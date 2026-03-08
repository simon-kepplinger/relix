defmodule Relix.Commands.Info do
  def dispatch([]),
    do: info()

  def dispatch([command]),
    do: info(String.upcase(command))

  def info() do
    [
      info("SERVER"),
      info("REPLICATION")
    ]
    |> Enum.join("\r\n")
  end

  def info("SERVER") do
    {os_family, os_name} = :os.type()
    {_, os_ver} = :os.version() |> then(fn {a, b, c} -> {:ok, "#{a}.#{b}.#{c}"} end)
    arch_bits = :erlang.system_info(:wordsize) * 8
    pid = :os.getpid() |> List.to_string()
    port = Application.get_env(:relix, :port)
    uptime_s = System.monotonic_time(:second) - Application.get_env(:relix, :start_time)

    executable =
      :init.get_argument(:progname)
      |> then(fn
        {:ok, [[path]]} -> List.to_string(path)
        _ -> "unknown"
      end)

    """
    # Server
    redis_version:#{Application.spec(:relix, :vsn)}
    redis_mode:standalone
    os:#{os_family} #{os_name} #{os_ver}
    arch_bits:#{arch_bits}
    process_id:#{pid}
    run_id:#{Application.get_env(:relix, :run_id)}
    tcp_port:#{port}
    uptime_in_seconds:#{uptime_s}
    uptime_in_days:#{div(uptime_s, 86400)}
    executable:#{executable}
    """
  end

  def info("REPLICATION") do
    """
    # Replication
    role:#{Relix.Replication.role()}
    master_replid:#{Relix.Replication.master_replid()}
    master_repl_offset:#{Relix.Replication.replication_offset()}
    """
  end
end
