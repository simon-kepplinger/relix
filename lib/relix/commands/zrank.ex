defmodule Relix.Commands.Zrank do
  def dispatch([key, member]) do
    Relix.Store.SortedSet.rank(key, member)
  end
end
