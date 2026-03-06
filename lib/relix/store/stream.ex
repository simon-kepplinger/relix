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

  def to_id({ts, seq}), do: "#{ts}-#{seq}"

  def set(key, {id, values}) do
    Relix.Store.set(key, {:stream, id})
    id = to_id(id)

    :ets.insert(@table, {{key, id}, values})

    id
  end

  def gt(key, id) do
    :ets.select(@table, [
      {
        {{:"$1", :"$2"}, :"$3"},
        [{:==, :"$1", key}, {:>, :"$2", id}],
        [{{:"$2", :"$3"}}]
      }
    ])
  end

  def range(key, start_id, stop_id) do
    :ets.select(@table, [
      {
        {{:"$1", :"$2"}, :"$3"},
        [{:==, :"$1", key}, {:>=, :"$2", start_id}, {:"=<", :"$2", stop_id}],
        [{{:"$2", :"$3"}}]
      }
    ])
  end
end
