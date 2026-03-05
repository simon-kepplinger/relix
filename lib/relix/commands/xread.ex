defmodule Relix.Commands.Xread do
  def dispatch([op | args]) do
    xread(String.upcase(op), args)
  end

  def xread("STREAMS", args) do
    center = div(length(args), 2)

    args
    |> Enum.split(center)
    |> then(fn {keys, ids} -> Enum.zip(keys, ids) end)
    |> Enum.map(&read/1)
  end

  def read({key, id}) do
    case Relix.Store.Stream.gt(key, id) do
      [res] -> [key, [res]]
      _ -> []
    end
  end
end
