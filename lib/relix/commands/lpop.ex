defmodule Relix.Commands.Lpop do
  def dispatch([key | arg]) do
    n =
      case arg do
        [n_str] -> :erlang.binary_to_integer(n_str)
        _ -> 1
      end

    Relix.Store.get(key)
    |> lpop(key, n)
  end

  def lpop({:list, len, list}, key, n) when len > 0 do
    {popped, list} = out(list, n, [])
    len = max(0, len - n)

    Relix.Store.set(key, {:list, len, list})

    reply =
      case popped do
        [single] -> single
        multiple -> multiple
      end

    {:reply, Relix.Resp.encode(reply)}
  end

  def lpop(_, _, _) do
    {:reply, Relix.Resp.encode(nil)}
  end

  def out(list, n, acc) when n <= 0 do
    {Enum.reverse(acc), list}
  end

  def out(list, n, acc) when n > 0 do
    case :queue.out(list) do
      {{:value, value}, list} ->
        out(list, n - 1, [value | acc])

      {:empty, _} ->
        {Enum.reverse(acc), list}
    end
  end
end
