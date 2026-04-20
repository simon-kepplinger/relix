defmodule Relix.Connection do
  @moduledoc """
  Handles all kind of TCP connections.

  At this point it would probably be better to split this module into multiple ones for each mode.
  """

  alias Relix.Resp
  alias Relix.CommandDispatcher
  alias Relix.CommandContext

  use GenServer

  require Logger

  defstruct [
    :client,
    :transaction,
    :target,
    subscribed: false,
    authenticated: false,
    dirty_watch: false,
    ack_caller: nil
  ]

  def start(client, target \\ :client) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        Relix.ConnectionSupervisor,
        {Relix.Connection, {client, target}}
      )

    :ok = :gen_tcp.controlling_process(client, pid)
  end

  def start_link(init) do
    GenServer.start_link(__MODULE__, init)
  end

  def init({client, target}) do
    :inet.setopts(client, active: true)
    nopass = Relix.Acl.get_user("default").nopass

    {
      :ok,
      %__MODULE__{
        client: client,
        transaction: nil,
        target: target,
        authenticated: nopass
      }
    }
  end

  def handle_info({:tcp, socket, data}, state) do
    Logger.debug("received #{inspect(data)}")
    {_, commands} = Resp.decode_all(data)

    commands
    |> Enum.each(&send(self(), {:command, socket, &1}))

    {:noreply, state}
  end

  # commands from :client
  def handle_info({:command, socket, {command, _}}, %{target: :client} = state) do
    ctx = %CommandContext{
      transaction: state.transaction,
      subscribed: state.subscribed,
      authenticated: state.authenticated,
      dirty_watch: state.dirty_watch
    }

    invocation = CommandDispatcher.dispatch(command, ctx)

    case invocation do
      # on successful PSYNC, register as replica connection
      {:reply, "PSYNC", {:batch, _} = resp, transaction} ->
        send_reply(socket, resp)
        Relix.Replication.Master.register(self())
        {:noreply, %{state | transaction: transaction, target: :replica}}

      # on successful AUTH, mark connection as authenticated
      {:reply, "AUTH", {:simple, "OK"} = resp, transaction} ->
        send_reply(socket, resp)
        {:noreply, %{state | transaction: transaction, authenticated: true}}

      # send respone to client
      {:reply, _, resp, transaction} ->
        send_reply(socket, resp)
        {:noreply, %{state | transaction: transaction}}
    end
  end

  # commands from :master
  def handle_info({:command, socket, {command, size}}, %{target: :master} = state) do
    ctx = %CommandContext{
      transaction: state.transaction,
      subscribed: state.subscribed,
      authenticated: true,
      dirty_watch: state.dirty_watch
    }

    invocation = CommandDispatcher.dispatch(command, ctx)

    {:reply, _, _, transaction} = invocation

    # only send REPLCONF response back to master
    case invocation do
      {:reply, "REPLCONF", resp, _} ->
        send_reply(socket, resp)

      _ ->
        :ok
    end

    Relix.Replication.incr_offset(size)

    {:noreply, %{state | transaction: transaction}}
  end

  # commands from :replica
  def handle_info({:command, _, {command, _}}, %{target: :replica} = state) do
    ["REPLCONF", "ACK", offset] = command
    offset = :erlang.binary_to_integer(offset)

    # send offset back to wait command
    send(state.ack_caller, {:replconf_ack, offset})

    {:noreply, %{state | ack_caller: nil}}
  end

  def handle_info({:replconf_getack, caller}, %{client: client} = state) do
    command = Resp.encode(["REPLCONF", "GETACK", "*"])

    :gen_tcp.send(client, command)

    {:noreply, %{state | ack_caller: caller}}
  end

  def handle_info({:replicate, command}, %{client: client} = state) do
    :gen_tcp.send(client, command)

    {:noreply, state}
  end

  def handle_info({:pubsub_message, channel, message}, %{client: client} = state) do
    command = Resp.encode(["message", channel, message])

    :gen_tcp.send(client, command)

    {:noreply, state}
  end

  def handle_info(:subscribe, %{subscribed: false} = state) do
    {:noreply, %{state | subscribed: true}}
  end

  def handle_info(:unsubscribe, %{subscribed: true} = state) do
    {:noreply, %{state | subscribed: false}}
  end

  def handle_info(:dirty_watch, state) do
    {:noreply, %{state | dirty_watch: true}}
  end

  def handle_info(:unwatch, state) do
    {:noreply, %{state | dirty_watch: false}}
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
end
