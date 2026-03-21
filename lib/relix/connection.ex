defmodule Relix.Connection do
  alias Relix.Resp
  alias Relix.CommandDispatcher

  use GenServer

  require Logger

  defstruct [:client, :transaction, is_replication_conn: false]

  def start(client, is_replication \\ false) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        Relix.ConnectionSupervisor,
        {Relix.Connection, {client, is_replication}}
      )

    :ok = :gen_tcp.controlling_process(client, pid)
  end

  def start_link(init) do
    GenServer.start_link(__MODULE__, init)
  end

  def init({client, is_replication}) do
    :inet.setopts(client, active: true)

    {:ok, %__MODULE__{client: client, transaction: nil, is_replication_conn: is_replication}}
  end

  def handle_info({:tcp, socket, data}, state) do
    Logger.debug("received #{inspect(data)}")
    {_, commands} = Resp.decode_all(data)

    for {command, size} <- commands do
      send(self(), {:command, socket, command})

      if state.is_replication_conn do
        send(self(), {:bytes_processed, size})
      end
    end

    {:noreply, state}
  end

  def handle_info({:command, socket, command}, state) do
    {:reply, resp, transaction} = CommandDispatcher.dispatch(command, state.transaction)

    # prevent replicas from sending replies
    if should_reply?(state, command) do
      send_reply(socket, resp)
    end

    # if this is a successful PSYNC command, "promote" this connection to a replica 
    if is_psync_success?(command, resp) do
      Relix.Replication.Master.register(self())
    end

    {:noreply, %{state | transaction: transaction}}
  end

  def handle_info({:replicate, command}, %{client: client} = state) do
    :gen_tcp.send(client, command)

    {:noreply, state}
  end

  def handle_info({:bytes_processed, bytes}, state) do
    Relix.Replication.incr_offset(bytes)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.debug("Connection closed #{inspect(state.client)}")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.warning("Tcp Error: #{reason}")
    {:stop, {:error, reason}, state}
  end

  def send_reply(socket, {:batch, list}) do
    Enum.each(list, &send_reply(socket, &1))
  end

  def send_reply(socket, reply) do
    :gen_tcp.send(socket, Resp.encode(reply))
  end

  def should_reply?(state, [command | _]) do
    not state.is_replication_conn or
      String.upcase(command) == "REPLCONF"
  end

  def is_psync_success?([command | _], {:batch, _}) do
    String.upcase(command) == "PSYNC"
  end

  def is_psync_success?(_, _) do
    false
  end
end
