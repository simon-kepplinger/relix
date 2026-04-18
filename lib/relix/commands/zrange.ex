defmodule Relix.Commands.Zrange do
  def dispatch([key, start, stop]) do
    Relix.Store.SortedSet.range(key, start, stop)
  end
end
