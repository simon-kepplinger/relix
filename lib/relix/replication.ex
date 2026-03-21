defmodule Relix.Replication do
  use GenServer

  defstruct [:role, :master_replid, replication_offset: 0]

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def role, do: GenServer.call(__MODULE__, :role)
  def master_replid, do: GenServer.call(__MODULE__, :master_replid)
  def replication_offset, do: GenServer.call(__MODULE__, :replication_offset)
  def incr_offset(by), do: GenServer.cast(__MODULE__, {:incr_offset, by})

  def init(_) do
    master_replid = :crypto.strong_rand_bytes(20) |> Base.encode16(case: :lower)
    role = if Application.get_env(:relix, :replicaof) != nil, do: :slave, else: :master

    {:ok, %__MODULE__{role: role, master_replid: master_replid}}
  end

  def handle_call(:role, _from, state), do: {:reply, state.role, state}
  def handle_call(:master_replid, _from, state), do: {:reply, state.master_replid, state}

  def handle_call(:replication_offset, _from, state),
    do: {:reply, state.replication_offset, state}

  def handle_cast({:incr_offset, by}, state) do
    {:noreply, %{state | replication_offset: state.replication_offset + by}}
  end
end
