defmodule Relix.Store.Stream do
  use GenServer

  @table __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table, [
      :named_table,
      :ordered_set,
      :public,
      read_concurrency: true,
      write_concurrency: :auto
    ])

    {:ok, nil}
  end

  def set(key, {id, values}) do
    Relix.Store.set(key, {:stream, id})
    :ets.insert(@table, {{key, id}, values})
  end
end
