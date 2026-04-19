defmodule Relix.Geo.Hash do
  # shared consants for encoder/decoder
  defmacro __using__(_opts) do
    quote do
      @min_latitude -85.05112878
      @max_latitude 85.05112878
      @min_longitude -180.0
      @max_longitude 180.0
      @latitude_range @max_latitude - @min_latitude
      @longitude_range @max_longitude - @min_longitude
    end
  end

  def to_hash(lat, long) do
    Relix.Geo.Hash.Encoder.encode(lat, long)
  end

  def from_hash(hash) do
    Relix.Geo.Hash.Decoder.decode(hash)
  end
end
