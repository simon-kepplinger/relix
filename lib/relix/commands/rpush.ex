defmodule Relix.Commands.Rpush do
  alias Relix.Resp

  def dispatch([key | value]) do
    Relix.Store.get(key)
    |> then(&(&1 || {:list, 0, :queue.new()}))
    |> rpush({key, value})
  end

  def dispatch(_),
    do: {:reply, "-ERR wrong number of arguments for rpush command\r\n"}

  def rpush({:list, len, list}, {key, value}) do
    {len, list} = append({len, list}, value)

    Relix.Store.set(key, {:list, len, list})

    {:reply, Resp.encode(len)}
  end

  def rpush(_),
    do: {:reply, "-ERR wrong type of value\r\n"}

  def append(len_list, []), do: len_list

  def append(len_list, [value | rest]) do
    len_list
    |> append(value)
    |> append(rest)
  end

  def append({len, list}, value) do
    {len + 1, :queue.in(value, list)}
  end
end
