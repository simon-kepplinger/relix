defmodule Relix.Keyspace.Watch do
  use GenServer

  @table __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    :ets.new(
      @table,
      [
        :named_table,
        :public,
        :bag,
        read_concurrency: true,
        write_concurrency: :auto
      ]
    )

    {:ok, nil}
  end

  def watch(key, pid) do
    :ets.insert(@table, {key, pid})
  end

  def unwatch(pid) do
    :ets.match_delete(@table, {:_, pid})
    send(pid, :unwatch)
  end

  def notify(key) do
    :ets.lookup(@table, key)
    |> Enum.each(fn {_, pid} -> send(pid, :dirty_watch) end)
  end

  @write_commands ~w(SET DEL INCR DECR LPUSH RPUSH LPOP BLPOP XADD ZADD ZREM GEOADD)

  def notify_write(command, [key | _]) when command in @write_commands do
    notify(key)
  end

  def notify_write(_, _), do: :ok
end
