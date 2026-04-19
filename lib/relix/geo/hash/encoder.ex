defmodule Relix.Geo.Hash.Encoder do
  import Bitwise
  use Relix.Geo.Hash

  @doc """
  Encodes latitude and longitude coordinates into a single integer using Morton encoding.

  ## Parameters
    - latitude: float latitude coordinate
    - longitude: float longitude coordinate

  ## Returns
    - integer: encoded geohash value
  """
  def encode(latitude, longitude) do
    # Normalize to the range 0-2^26
    normalized_latitude = :math.pow(2, 26) * (latitude - @min_latitude) / @latitude_range
    normalized_longitude = :math.pow(2, 26) * (longitude - @min_longitude) / @longitude_range

    # Truncate to integers
    normalized_latitude_int = trunc(normalized_latitude)
    normalized_longitude_int = trunc(normalized_longitude)

    interleave(normalized_latitude_int, normalized_longitude_int)
  end

  # Spreads bits of a 32-bit integer to occupy even positions in a 64-bit integer.
  defp spread_int32_to_int64(v) do
    result = v &&& 0xFFFFFFFF
    result = (result ||| result <<< 16) &&& 0x0000FFFF0000FFFF
    result = (result ||| result <<< 8) &&& 0x00FF00FF00FF00FF
    result = (result ||| result <<< 4) &&& 0x0F0F0F0F0F0F0F0F
    result = (result ||| result <<< 2) &&& 0x3333333333333333
    result = (result ||| result <<< 1) &&& 0x5555555555555555
    result
  end

  # Interleaves bits of two 32-bit integers to create a single 64-bit Morton code.
  defp interleave(x, y) do
    spread_x = spread_int32_to_int64(x)
    spread_y = spread_int32_to_int64(y)
    y_shifted = spread_y <<< 1
    spread_x ||| y_shifted
  end
end
