defmodule Relix.Commands.Xread do
  def dispatch(args) do
    {_, res} = op(args)

    res
  end

  def op([op | args]) do
    op(String.upcase(op), args)
  end

  def op("BLOCK", [timeout | args]) do
    timeout = :erlang.binary_to_integer(timeout)

    case op(args) do
      # for simplicity, we only support one key and one id for blocking read
      {{[key | _], [id | _]}, [[]]} -> wait_for(key, parse_id(key, id), timeout)
      res -> res
    end
  end

  def op("STREAMS", args) do
    {keys, ids} = parse_args(args)

    res = xread(keys, ids)

    {{keys, ids}, res}
  end

  def xread(keys, ids) do
    Enum.zip(keys, ids)
    |> Enum.map(&read/1)
  end

  def parse_args(args) do
    center = div(length(args), 2)

    args
    |> Enum.split(center)
  end

  def read({key, id}) do
    id = parse_id(key, id)

    case Relix.Store.Stream.gt(key, id) do
      [res] -> [key, [res]]
      _ -> []
    end
  end

  # blocking read
  def wait_for(key, id, timeout) do
    reply_fn = fn
      :timeout -> :null_array
      value -> [[key, [value]]]
    end

    res =
      Relix.Keyspace.Serializer.run(key, fn _ ->
        {:wait, timeout, reply_fn}
      end)

    {{key, id}, res}
  end

  defp parse_id(key, "$") do
    Relix.Commands.Xadd.get_last_id(key)
    |> Relix.Store.Stream.to_id()
  end

  defp parse_id(_, id) do
    id
  end
end
