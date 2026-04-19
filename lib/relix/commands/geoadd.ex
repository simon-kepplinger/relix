defmodule Relix.Commands.Geoadd do
  def dispatch([key, long, lat, member]) do
    long = :erlang.binary_to_float(long)
    lat = :erlang.binary_to_float(lat)

    add(key, long, lat, member)
  end

  def add(_, long, lat, _)
      when long < -180 or long > 180 or lat < -85.05112878 or lat > 85.05112878 do
    {:error, "ERR invalid longitude,latitude pair #{long},#{lat}"}
  end

  def add(key, long, lat, member) do
    hash = Relix.Geo.Hash.to_hash(lat, long) * 1.0

    Relix.Store.SortedSet.add(key, hash, member)
  end
end
