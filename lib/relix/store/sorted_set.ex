defmodule Relix.Store.SortedSet do
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

  def add(key, score, member) do
    case score(key, member) do
      nil ->
        :ets.insert(@table, {{key, score, member}, nil})
        Relix.Store.set(key, :zset)
        1

      old_score ->
        :ets.delete(@table, {key, old_score, member})
        :ets.insert(@table, {{key, score, member}, nil})
        0
    end
  end

  def score(key, member) do
    case :ets.select(@table, [{{{key, :"$1", member}, :_}, [], [:"$1"]}]) do
      [score] -> score
      [] -> nil
    end
  end

  def rank(key, member) do
    case score(key, member) do
      nil ->
        nil

      s ->
        :ets.select_count(@table, [
          {{{key, :"$1", :"$2"}, :_},
           [{:orelse, {:>, s, :"$1"}, {:andalso, {:==, s, :"$1"}, {:<, :"$2", member}}}], [true]}
        ])
    end
  end

  def range(key, start_idx, stop_idx) do
    all = :ets.select(@table, [{{{key, :"$1", :"$2"}, :_}, [], [{{:"$2", :"$1"}}]}])
    total = length(all)

    start_idx = normalize_index(start_idx, total)
    stop_idx = normalize_index(stop_idx, total)

    if start_idx > stop_idx or start_idx >= total do
      []
    else
      Enum.slice(all, start_idx..stop_idx)
      |> Enum.map(fn {member, _} -> member end)
    end
  end

  def remove(key, members) do
    Enum.reduce(members, 0, fn member, acc ->
      case score(key, member) do
        nil ->
          acc

        s ->
          :ets.delete(@table, {key, s, member})
          acc + 1
      end
    end)
  end

  def card(key) do
    :ets.select_count(@table, [{{{key, :_, :_}, :_}, [], [true]}])
  end

  defp normalize_index(idx, total) when is_binary(idx),
    do: normalize_index(String.to_integer(idx), total)

  defp normalize_index(idx, total) when idx < 0, do: max(0, total + idx)
  defp normalize_index(idx, _total), do: idx
end
