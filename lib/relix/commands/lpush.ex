defmodule Relix.Commands.Lpush do
  def dispatch(side, [key | values]) do
    Relix.Keyspace.Serializer.run(key, fn consume ->
      {values, n} = consume.(values)

      Relix.Store.get(key)
      |> then(&(&1 || {:list, 0, :queue.new()}))
      |> lpush({side, key, values})
      |> Kernel.+(n)
    end)
  end

  def dispatch(_),
    do: {:reply, "-ERR wrong number of arguments for lpush command\r\n"}

  def lpush({:list, len, list}, {side, key, values}) do
    {len, list} = push({len, list}, side, values)

    Relix.Store.set(key, {:list, len, list})

    len
  end

  def lpush(_),
    do: {:error, "ERR wrong type of value"}

  def push(len_list, _, []), do: len_list

  def push(len_list, side, [value | rest]) do
    len_list
    |> push(side, value)
    |> push(side, rest)
  end

  def push({len, list}, :left, value),
    do: {len + 1, :queue.in_r(value, list)}

  def push({len, list}, :right, value),
    do: {len + 1, :queue.in(value, list)}
end
