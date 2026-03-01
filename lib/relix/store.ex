defmodule Relix.Store do
  use GenServer

  @table __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table, [
      :named_table,
      :set,
      :public,
      read_concurrency: true,
      write_concurrency: :auto
    ])

    {:ok, nil}
  end

  def set(key, value) do
    :ets.insert(@table, {key, value})
  end

  def set(key, value, ttl_ms) do
    :ets.insert(@table, {key, value, now() + ttl_ms})
  end

  def get(key) do
    case :ets.lookup(@table, key) do
      [{^key, value}] -> value
      [{^key, value, exp}] -> check_exp({key, value, exp})
      _ -> nil
    end
  end

  defp check_exp({key, value, exp}) do
    if now() < exp do
      value
    else
      :ets.delete(@table, key)
      nil
    end
  end

  defp now(),
    do: System.monotonic_time(:millisecond)
end
