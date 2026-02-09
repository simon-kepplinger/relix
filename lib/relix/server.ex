defmodule Relix.Server do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def listen(%{port: port}) do
    GenServer.cast(__MODULE__, {:listen, port})
  end

  def init(_) do
    {:ok, %{}}
  end

  @doc """
  Listen for incoming connections
  """
  def handle_cast({:listen, port}, _) do
    Logger.info("oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo")

    {:ok, socket} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])

    Logger.info("Server initialized")
    Logger.info("Ready to accept connections tcp")

    accept(socket)
  end

  @doc """
  Handle incoming connections and spawn a new process for each client
  """
  def accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    Logger.debug("Client connected #{inspect(client)}")

    {:ok, pid} =
      DynamicSupervisor.start_child(
        Relix.ConnectionSupervisor,
        {Relix.Connection, client}
      )

    :ok = :gen_tcp.controlling_process(client, pid)

    accept(socket)
  end
end
