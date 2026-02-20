defmodule Relix.Commands.Blpop do
  def dispatch([key | [arg]]) do
    {timeout, _} = Float.parse(arg)
    timeout_ms = trunc(timeout * 1000)

    Relix.Keyspace.Serializer.run(key, fn _ ->
      Relix.Store.get(key)
      |> blpop(key, timeout_ms)
    end)
  end

  # just lpop if there are items in the list
  def blpop({:list, len, list}, key, _) when len > 0 do
    case Relix.Commands.Lpop.lpop({:list, len, list}, key, 1) do
      nil -> :null_array
      value -> [key, value]
    end
  end

  # wait for an item to be pushed
  def blpop(_, key, timeout) do
    reply_fn = fn
      :timeout -> :null_array
      value -> [key, value]
    end

    {:wait, timeout, reply_fn}
  end
end
