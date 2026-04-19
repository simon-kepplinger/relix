defmodule Relix.Config do
  use GenServer

  defstruct [:dir, :dbfilename]

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def init(_) do
    {:ok, %__MODULE__{
      dir: Application.get_env(:relix, :dir),
      dbfilename: Application.get_env(:relix, :dbfilename)
    }}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end
end
