defmodule Relix.Commands.Xrange do
  def dispatch([key, start, stop]) do
    start = normalize(start)
    stop = normalize(stop)

    Relix.Store.Stream.range(key, start, stop)
  end

  def normalize("-"), do: 0
  def normalize("+"), do: <<255>>

  def normalize(id) do
    case String.contains?(id, "-") do
      true -> id
      false -> "#{id}-0"
    end
  end
end
