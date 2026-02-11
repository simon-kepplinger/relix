defmodule Relix.Commands.Lpush do
  alias Relix.Resp

  def dispatch([key | value]) do
    Relix.Store.get(key)
    |> then(&(&1 || {:list, 0, :queue.new()}))
    |> lpush({key, value})
  end

  def dispatch(_),
    do: {:reply, "-ERR wrong number of arguments for lpush command\r\n"}

  def lpush({:list, len, list}, {key, value}) do
    {len, list} = prepend({len, list}, value)

    Relix.Store.set(key, {:list, len, list})

    {:reply, Resp.encode(len)}
  end

  def lpush(_),
    do: {:reply, "-ERR wrong type of value\r\n"}

  def prepend(len_list, []), do: len_list

  def prepend(len_list, [value | rest]) do
    len_list
    |> prepend(value)
    |> prepend(rest)
  end

  def prepend({len, list}, value) do
    {len + 1, :queue.in_r(value, list)}
  end
end
