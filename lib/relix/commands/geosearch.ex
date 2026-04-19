defmodule Relix.Commands.Geosearch do
  def dispatch([key, op | args]) do
    op = String.upcase(op)

    op(op, key, args)
  end

  def op("FROMLONLAT", key, [long, lat, op | args]) do
    long = :erlang.binary_to_float(long)
    lat = :erlang.binary_to_float(lat)
    op = String.upcase(op)

    from_lonlat(key, {lat, long}, op, args)
  end

  def from_lonlat(key, pos, "BYRADIUS", [value, unit]) do
    distance = :erlang.binary_to_float(value) |> to_meters(unit)

    Relix.Store.SortedSet.range(key, 0, -1)
    |> Enum.map(fn member -> {member, Relix.Store.SortedSet.score(key, member)} end)
    |> Enum.map(&with_distance(&1, pos))
    |> Enum.filter(fn {_, _, dist} -> dist <= distance end)
    |> Enum.map(fn {member, _, _} -> member end)
  end

  def with_distance({member, score}, pos) do
    distance =
      Relix.Geo.Hash.from_hash(score)
      |> Relix.Geo.Distance.distance(pos)

    {member, score, distance}
  end

  def to_meters(value, "m"), do: value
  def to_meters(value, "km"), do: value * 1000
  def to_meters(value, "mi"), do: value * 1609.344
  def to_meters(value, "ft"), do: value * 0.3048
end
