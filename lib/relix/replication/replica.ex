defmodule Relix.Replication.Replica do
  require Logger
  use GenServer

  defstruct [:master_host, :master_port, :socket]

  def start_link(replicaof) do
    GenServer.start_link(__MODULE__, replicaof, name: __MODULE__)
  end

  def init(replicaof) do
    [host, port] = String.split(replicaof, " ")

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

    # trigger handshake
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

    {:fullsync, replid, offset} =
      with {:ok, {"PONG", _}} <- call_socket(["PING"], state),
           {:ok, {"OK", _}} <- call_socket(["REPLCONF", "listening-port", "#{port}"], state),
           {:ok, {"OK", _}} <- call_socket(["REPLCONF", "capa", "eof"], state),
           {:ok, {resp, _}} <- call_socket(["PSYNC", "?", "-1"], state) do
        parse_psync(resp, state)
      end

    Logger.info("Handshake with master successful, replid=#{replid}, offset=#{offset}")

    # listen for commands from master
    Relix.Connection.start(state.socket, :master)

    {:noreply, state}
  end

  def parse_psync("FULLRESYNC " <> rest, state) do
    [replid, offset] = String.split(rest)

    # read RDB file length first
    {:ok, "$" <> length_str} = :gen_tcp.recv(state.socket, 0, 5_000)
    rdb_length = length_str |> String.trim() |> String.to_integer()

    IO.puts("Expecting RDB file of size #{rdb_length} bytes")

    # read exact file bytes and switch back to raw mode
    :inet.setopts(state.socket, packet: :raw)

    rdb_stream(state.socket, rdb_length)
    |> Relix.Rdb.new()
    |> Relix.Rdb.process()

    IO.puts("RDB file processed")

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

  defp rdb_stream(socket, rdb_length, chunk_size \\ 65_536) do
    Stream.unfold(rdb_length, fn
      0 ->
        nil

      remaining ->
        to_read = min(remaining, chunk_size)
        {:ok, chunk} = :gen_tcp.recv(socket, to_read, 5_000)
        {chunk, remaining - byte_size(chunk)}
    end)
  end
end
