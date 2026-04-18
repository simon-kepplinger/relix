defmodule Relix.Commands.Zcard do
  def dispatch([key]) do
    Relix.Store.SortedSet.card(key)
  end
end
