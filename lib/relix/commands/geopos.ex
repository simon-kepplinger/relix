defmodule Relix.Commands.Geopos do
  def dispatch([key | members]) do
    Enum.map(members, fn member ->
      case Relix.Store.SortedSet.score(key, member) do
        nil -> :null_array
        score ->
        {lat, lon} = Relix.Geo.Hash.from_hash(score)
        [lon, lat]
      end
    end)
  end
end
