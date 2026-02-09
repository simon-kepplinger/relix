defmodule Relix.Connection do
  use GenServer

  require Logger

  def start_link(client) do
    GenServer.start_link(__MODULE__, client)
  end

  def init(client) do
    :inet.setopts(client, active: true)

    {:ok, %{client: client}}
  end

  def handle_info({:tcp, socket, _}, state) do
    :gen_tcp.send(socket, "+PONG\r\n")
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.debug("Connection closed #{inspect(state.socket)}")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.warning("Tcp Error: #{reason}")
    {:stop, :normal, state}
  end
end
