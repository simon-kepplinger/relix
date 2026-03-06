defmodule Relix.Commands.Incr do
  def dispatch([key]) do
    Relix.Keyspace.Serializer.run(key, fn _ ->
      case Relix.Store.get(key) do
        nil -> incr(key, {:string, "0"})
        val -> incr(key, val)
      end
    end)
  end

  def incr(key, {:string, value}) do
    case Integer.parse(value) do
      {num, ""} ->
        num = num + 1
        Relix.Store.set(key, {:string, Integer.to_string(num)})
        num

      _ ->
        {:error, "ERR value is not an integer or out of range"}
    end
  end

  def incr(_),
    do: {:error, "ERR value is not an integer or out of range"}
end
