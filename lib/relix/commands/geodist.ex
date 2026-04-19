defmodule Relix.Commands.Geodist do
  def dispatch([key, member1, member2]) do
    score1 = Relix.Store.SortedSet.score(key, member1)
    score2 = Relix.Store.SortedSet.score(key, member2)

    case {score1, score2} do
      {nil, _} ->
        nil

      {_, nil} ->
        nil

      {score1, score2} ->
        Relix.Geo.Distance.distance(
          Relix.Geo.Hash.from_hash(score1),
          Relix.Geo.Hash.from_hash(score2)
        )
    end
  end
end
