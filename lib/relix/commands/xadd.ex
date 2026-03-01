defmodule Relix.Commands.Xadd do
  def dispatch([key, id | key_value_list]) do
    key_value_map =
      key_value_list
      |> Enum.chunk_every(2)
      |> Enum.map(fn [k, v] -> {k, v} end)
      |> Map.new()

    Relix.Store.set(key, {:stream, {id, key_value_map}})

    id
  end
end
