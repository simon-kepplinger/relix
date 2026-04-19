defmodule Relix.Geo.Distance do
  @earth_radius_meters 6_372_797.560856
  @deg_to_rad :math.pi() / 180.0

  # https://github.com/redis/redis/blob/4322cebc1764d433b3fce3b3a108252648bf59e7/src/geohash_helper.c#L228C1-L228C72
  def distance({lat1, lon1}, {lat2, lon2}) do
    lon1r = lon1 * @deg_to_rad
    lon2r = lon2 * @deg_to_rad
    v = :math.sin((lon2r - lon1r) / 2)

    # Same longitude: the haversine collapses to R * |Δφ|, no trig needed.
    if v == 0.0 do
      lat_distance(lat1, lat2)
    else
      lat1r = lat1 * @deg_to_rad
      lat2r = lat2 * @deg_to_rad
      u = :math.sin((lat2r - lat1r) / 2)
      a = u * u + :math.cos(lat1r) * :math.cos(lat2r) * v * v
      2.0 * @earth_radius_meters * :math.asin(:math.sqrt(a))
    end
  end

  defp lat_distance(lat1, lat2) do
    @earth_radius_meters * abs((lat2 - lat1) * @deg_to_rad)
  end
end
