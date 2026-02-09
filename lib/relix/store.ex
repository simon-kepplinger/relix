defmodule Relix.Store do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    :ets.new(__MODULE__, [
      :named_table,
      :set,
      :public,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, nil}
  end

  def set(key, value) do
    :ets.insert(__MODULE__, {key, value})
  end

  def set(key, value, ttl_ms) do
    :ets.insert(__MODULE__, {key, value, now() + ttl_ms})
  end

  def get(key) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, value}] -> value
      [{^key, value, exp}] -> check_exp({key, value, exp})
      _ -> nil
    end
  end

  defp check_exp({key, value, exp}) do
    if now() < exp do
      value
    else
      :ets.delete(__MODULE__, key)
      nil
    end
  end

  defp now(),
    do: System.monotonic_time(:millisecond)
end
