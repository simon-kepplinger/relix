defmodule Server do
  require Logger
  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: Relix.ConnectionSupervisor, strategy: :one_for_one},
      {Task, fn -> Server.listen() end}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Relix.Supervisor)
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    Logger.info("oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo")

    {:ok, socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])

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

defmodule CLI do
  def main(_args) do
    {:ok, _pid} = Application.ensure_all_started(:relix)

    # Run forever
    Process.sleep(:infinity)
  end
end
