defmodule Relix.Commands.Xadd do
  def dispatch([key, id | kv_list]) do
    Relix.Keyspace.Serializer.run(key, fn consume ->
      last_id = get_last_id(key)

      id = parse_id(id, last_id)
      kv_map = kv_list_to_map(kv_list)

      with {:ok, id} <- validate_id(id, last_id) do
        id = Relix.Store.Stream.set(key, {id, kv_map})

        consume.([[id, kv_map]])

        id
      end
    end)
  end

  def get_last_id(key) do
    case Relix.Store.get(key) do
      {:stream, last_id} -> last_id
      _ -> {0, 0}
    end
  end

  def kv_list_to_map(kv_list) do
    kv_list
    |> Enum.chunk_every(2)
    |> Enum.map(fn [k, v] -> {k, v} end)
    |> Map.new()
  end

  def parse_id("*", {last_ts, seq}) do
    ts = System.system_time(:millisecond)

    case ts < last_ts do
      true -> {last_ts, seq + 1}
      false -> {ts, 0}
    end
  end

  def parse_id(id, {last_ts, last_seq}) do
    [ts_str, seq_str] = String.split(id, "-")
    {ts, _} = Integer.parse(ts_str)

    {seq, _} =
      cond do
        ts == last_ts and seq_str == "*" -> {last_seq + 1, ""}
        seq_str == "*" -> {0, ""}
        true -> Integer.parse(seq_str)
      end

    {ts, seq}
  end

  def validate_id({0, 0}, _),
    do: {:error, "ERR The ID specified in XADD must be greater than 0-0"}

  def validate_id({ts, seq}, {last_ts, last_seq})
      when ts < last_ts or (ts == last_ts and seq <= last_seq),
      do:
        {:error,
         "ERR The ID specified in XADD is equal or smaller than the target stream top item"}

  def validate_id(id, _), do: {:ok, id}
end
