defmodule Relix.Commands.Wait do
  def dispatch([replicas, timeout]) do
    replicas = :erlang.binary_to_integer(replicas)
    timeout = :erlang.binary_to_integer(timeout)

    replica_pids = Relix.Replication.Master.get_replicas()
    offset = Relix.Replication.replication_offset()

    replicas_connected = MapSet.size(replica_pids)

    cond do
      replicas_connected == 0 -> 0
      offset == 0 -> replicas_connected
      true -> dispatch(replicas, timeout, offset, replica_pids)
    end
  end

  def dispatch(replicas, timeout, offset, replica_pids) do
    # send a REPLCONF ACK over each replica connection
    for pid <- replica_pids do
      send(pid, {:replconf_getack, self()})
    end

    deadline = System.monotonic_time(:millisecond) + timeout

    wait(offset, replicas, deadline, 0)
  end

  defp wait(_, threshold, _, count) when count >= threshold,
    do: count

  defp wait(offset, threshold, deadline, count) do
    remaining = max(0, deadline - System.monotonic_time(:millisecond))

    receive do
      {:replconf_ack, actual} when actual >= offset ->
        wait(offset, threshold, deadline, count + 1)

      {:replconf_ack, _} ->
        wait(offset, threshold, deadline, count)
    after
      remaining -> count
    end
  end
end
