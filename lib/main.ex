defmodule Relix.Application do
  use Application

  @args [
    port: :integer,
    replicaof: :string,
    dir: :string,
    dbfilename: :string,
    requirepass: :string,
    appendonly: :string,
    appenddirname: :string,
    appendfilename: :string,
    appendfsync: :string
  ]

  def start(_type, _args) do
    setup_envs()

    replicaof = Application.get_env(:relix, :replicaof)
    appendonly = Application.get_env(:relix, :appendonly)

    children =
      [
        Relix.Config,
        Relix.Acl,
        Relix.Store,
        Relix.Store.Stream,
        Relix.Store.SortedSet,
        Relix.Replication,
        Relix.Replication.Master,
        Relix.Keyspace.Watch,
        appendonly == "yes" && Relix.Aof,
        replicaof != nil && {Relix.Replication.Replica, replicaof},
        {Registry, keys: :unique, name: Relix.Keyspace.Registry},
        {Registry, keys: :duplicate, name: Relix.PubSub.Registry},
        # consider putting under a separate store supervisor
        {DynamicSupervisor, name: Relix.Keyspace.Supervisor, strategy: :one_for_one},
        {DynamicSupervisor, name: Relix.ConnectionSupervisor, strategy: :one_for_one},
        Relix.Server
      ]
      |> Enum.filter(& &1)

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one, name: Relix.Supervisor)

    # start listening to
    Relix.Server.listen(%{port: Application.get_env(:relix, :port)})

    {:ok, pid}
  end

  defp setup_envs do
    Application.put_env(:relix, :start_time, System.monotonic_time(:second))
    Application.put_env(:relix, :run_id, generate_run_id())

    {opts, _, _} =
      :init.get_plain_arguments()
      |> Enum.map(&List.to_string/1)
      |> OptionParser.parse(strict: @args)

    for {key, val} <- opts do
      Application.put_env(:relix, key, val)
    end
  end

  defp generate_run_id do
    :crypto.strong_rand_bytes(16)
    |> Base.hex_encode32(case: :lower, padding: false)
  end
end

defmodule CLI do
  def main(_args) do
    {:ok, _pid} = Application.ensure_all_started(:relix)

    # Run forever
    Process.sleep(:infinity)
  end
end
