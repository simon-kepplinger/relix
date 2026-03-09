defmodule Relix.Connection do
  alias Relix.Resp
  alias Relix.CommandDispatcher

  use GenServer

  require Logger

  defstruct [:client, :transaction]

  def start_link(client) do
    GenServer.start_link(__MODULE__, client)
  end

  def init(client) do
    :inet.setopts(client, active: true)

    {:ok, %{client: client, transaction: nil}}
  end

  def handle_info({:tcp, socket, data}, state) do
    Logger.debug("received #{inspect(data)}")

    {:ok, command} = Resp.decode(data)
    {:reply, resp, transaction} = CommandDispatcher.dispatch(command, state.transaction)

    send_reply(socket, resp)

    {:noreply, %{state | transaction: transaction}}
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
