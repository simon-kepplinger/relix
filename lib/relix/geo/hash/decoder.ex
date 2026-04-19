defmodule Relix.Geo.Hash.Decoder do
  import Bitwise
  use Relix.Geo.Hash

  @doc """
  Decodes an encoded geohash value back to latitude and longitude coordinates.

  ## Parameters
    - geo_code: integer encoded geohash value

  ## Returns
    - tuple: {latitude, longitude} coordinates
  """
  def decode(geo_code) when is_float(geo_code), do: decode(trunc(geo_code))

  def decode(geo_code) do
    y = geo_code >>> 1
    x = geo_code

    # Compact bits back to 32-bit ints
    grid_latitude_number = compact_int64_to_int32(x)
    grid_longitude_number = compact_int64_to_int32(y)

    convert_grid_numbers_to_coordinates(grid_latitude_number, grid_longitude_number)
  end

  # Compacts spread bits back to a 32-bit integer
  defp compact_int64_to_int32(v) do
    v = v &&& 0x5555555555555555
    v = (v ||| v >>> 1) &&& 0x3333333333333333
    v = (v ||| v >>> 2) &&& 0x0F0F0F0F0F0F0F0F
    v = (v ||| v >>> 4) &&& 0x00FF00FF00FF00FF
    v = (v ||| v >>> 8) &&& 0x0000FFFF0000FFFF
    (v ||| v >>> 16) &&& 0x00000000FFFFFFFF
  end

  # Converts grid cell numbers back to geographic coordinates
  defp convert_grid_numbers_to_coordinates(grid_latitude_number, grid_longitude_number) do
    # Calculate the grid boundaries
    grid_latitude_min =
      @min_latitude + @latitude_range * (grid_latitude_number / :math.pow(2, 26))

    grid_latitude_max =
      @min_latitude + @latitude_range * ((grid_latitude_number + 1) / :math.pow(2, 26))

    grid_longitude_min =
      @min_longitude + @longitude_range * (grid_longitude_number / :math.pow(2, 26))

    grid_longitude_max =
      @min_longitude + @longitude_range * ((grid_longitude_number + 1) / :math.pow(2, 26))

    # Calculate the center point of the grid cell
    latitude = (grid_latitude_min + grid_latitude_max) / 2
    longitude = (grid_longitude_min + grid_longitude_max) / 2

    {latitude, longitude}
  end
end
