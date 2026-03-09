defmodule Relix.Replication.Replica do
  require Logger
  use GenServer

  defstruct [:master_host, :master_port, :socket]

  def start_link(replicaof) do
    GenServer.start_link(__MODULE__, replicaof, name: __MODULE__)
  end

  def init(replicaof) do
    [host, port] = String.split(replicaof, " ")

    IO.inspect({host, port})

    {:ok, socket} =
      :gen_tcp.connect(
        String.to_charlist(host),
        String.to_integer(port),
        [
          :binary,
          active: false,
          packet: :line
        ]
      )

    Process.send_after(self(), :handshake, 10)

    {
      :ok,
      %__MODULE__{
        master_host: host,
        master_port: String.to_integer(port),
        socket: socket
      }
    }
  end

  def handle_info(:handshake, state) do
    port = Application.get_env(:relix, :port)

    Logger.info("Starting handshake with master #{state.master_host}:#{state.master_port}")

    {_, replid, offset} =
      with {:ok, "PONG"} <- call_socket(["PING"], state),
           {:ok, "OK"} <- call_socket(["REPLCONF", "listening-port", "#{port}"], state),
           {:ok, "OK"} <- call_socket(["REPLCONF", "capa", "eof"], state),
           {:ok, resp} <- call_socket(["PSYNC", "?", "-1"], state) do
        parse_psync(resp, state)
      end

    Logger.info("Handshake with master successful, replid=#{replid}, offset=#{offset}")

    {:noreply, state}
  end

  def parse_psync("FULLRESYNC " <> rest, state) do
    [replid, offset] = String.split(rest)

    {:ok, file} = :gen_tcp.recv(state.socket, 0, 5_000)
    Logger.info("Received RDB file of size #{byte_size(file)} bytes")

    {:fullsync, replid, String.to_integer(offset)}
  end

  def call_socket(message, state) do
    :gen_tcp.send(state.socket, Relix.Resp.encode(message))

    case :gen_tcp.recv(state.socket, 0, 5_000) do
      {:ok, data} ->
        Relix.Resp.decode(data)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
