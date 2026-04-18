defmodule Relix.Commands.Zscore do
  def dispatch([key, member]) do
    case Relix.Store.SortedSet.score(key, member) do
      nil -> nil
      score -> Float.to_string(score)
    end
  end
end
