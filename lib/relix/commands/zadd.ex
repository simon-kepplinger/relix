defmodule Relix.Commands.Zadd do
  alias Relix.Store

  def dispatch([key, score, member]) do
    {score, _} = Float.parse(score)
    Store.SortedSet.add(key, score, member)
  end
end
