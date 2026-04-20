defmodule Relix.Replication.Master do
  use GenServer

  require Logger

  @write_commands MapSet.new([
    "SET", "DEL", "INCR", "DECR",
    "LPUSH", "RPUSH", "LPOP", "BLPOP",
    "XADD",
    "ZADD", "ZREM",
    "GEOADD"
  ])

  defstruct replicas: MapSet.new()

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def register(pid) do
    Logger.debug("registering replica")
    GenServer.call(__MODULE__, {:register, pid})
  end

  def propagate(command) do
    GenServer.cast(__MODULE__, {:propagate, command})
  end

  def get_replicas do
    GenServer.call(__MODULE__, :get_replicas)
  end

  def handle_call({:register, pid}, _from, state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | replicas: MapSet.put(state.replicas, pid)}}
  end

  def handle_call(:get_replicas, _from, state) do
    {:reply, state.replicas, state}
  end

  def handle_cast({:propagate, command}, state) do
    if is_write_command?(command) do
      command
      |> Relix.Resp.encode()
      |> send_command(state)

    end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    Logger.error("Replica #{inspect(pid)} is down")
    {:noreply, %{state | replicas: MapSet.delete(state.replicas, pid)}}
  end

  def send_command(command, state) do
    Enum.each(state.replicas, &send(&1, {:replicate, command}))
    Relix.Replication.incr_offset(byte_size(command))
  end

  def is_write_command?([command | _]) do
    MapSet.member?(@write_commands, String.upcase(command))
  end
end
