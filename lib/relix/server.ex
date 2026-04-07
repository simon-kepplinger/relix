defmodule Relix.Server do
  use GenServer

  alias Relix.Config

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
    dir = Config.get(:dir)
    dbfilename = Config.get(:dbfilename)

    Logger.info("oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo")
    Logger.info("Running mode=standalone, port=#{port}.")

    if dir && dbfilename do
      read_rdb(dir, dbfilename)
    end

    {:ok, socket} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])

    Logger.info("Server initialized")
    Logger.info("Ready to accept connections tcp")

    accept(socket)
  end

  defp read_rdb(dir, dbfilename) do
    Logger.info("Read RDB from #{dir}/#{dbfilename}")
    path = Path.join(dir, dbfilename)

    if File.exists?(path) do
      Logger.info("Loading RDB file from #{path}")

      File.stream!(path)
      |> Relix.Rdb.new()
      |> Relix.Rdb.process()
    else
      Logger.warning("RDB file not found at #{path}, starting with empty dataset")
    end
  end

  @doc """
  Handle incoming connections and spawn a new process for each client
  """
  def accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    Logger.debug("Client connected #{inspect(client)}")
    Relix.Connection.start(client)

    accept(socket)
  end
end
