defmodule Relix.Commands.Zrem do
  def dispatch([key | members]) do
    Relix.Store.SortedSet.remove(key, members)
  end
end
