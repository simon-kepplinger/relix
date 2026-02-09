defmodule Relix.Application do
  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: Relix.ConnectionSupervisor, strategy: :one_for_one},
      Relix.Server
    ]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one, name: Relix.Supervisor)

    # start listening to
    Relix.Server.listen(%{port: 6379})

    {:ok, pid}
  end
end

defmodule CLI do
  def main(_args) do
    {:ok, _pid} = Application.ensure_all_started(:relix)

    # Run forever
    Process.sleep(:infinity)
  end
end
