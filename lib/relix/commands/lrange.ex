defmodule Relix.Commands.Lrange do
  alias Relix.Resp

  def dispatch([key, from, to]) do
    list = Relix.Store.get(key)

    lrange(
      list,
      :erlang.binary_to_integer(from),
      :erlang.binary_to_integer(to)
    )
  end

  def lrange({:list, len, list}, from, to) do
    {from, to} = range(len, from, to)

    range = split(list, from, to)

    {:reply, Resp.encode(:queue.to_list(range))}
  end

  def lrange(_, _, _),
    do: {:reply, "*0\r\n"}

  def split(_, from, to) when to < from,
    do: :queue.new()

  def split(list, from, to) do
    {_, tail} = :queue.split(from, list)
    {range, _} = :queue.split(to - from + 1, tail)

    range
  end

  def range(len, from, to) when from < 0,
    do: range(len, max(len + from, 0), to)

  def range(len, from, to) when to < 0,
    do: range(len, from, len + to)

  def range(len, from, to),
    do: {min(max(from, 0), len - 1), min(to, len - 1)}
end
