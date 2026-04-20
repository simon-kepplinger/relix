defmodule Relix.Config do
  use GenServer

  defstruct [
    :dir,
    :dbfilename,
    :appendonly,
    :appenddirname,
    :appendfilename,
    :appendfsync
  ]

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def init(_) do
    {:ok,
     %__MODULE__{
       dir: Application.get_env(:relix, :dir, File.cwd!()),
       dbfilename: Application.get_env(:relix, :dbfilename),
       appendonly: Application.get_env(:relix, :appendonly, "no"),
       appenddirname: Application.get_env(:relix, :appenddirname, "appendonlydir"),
       appendfilename: Application.get_env(:relix, :appendfilename, "appendonly.aof"),
       appendfsync: Application.get_env(:relix, :appendfsync, "everysec")
     }}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end
end
