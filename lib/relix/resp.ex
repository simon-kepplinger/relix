defmodule Relix.Resp do
  alias Relix.Resp

  def decode_all(data) do
    {status, value, _} = Resp.Decode.decode_all(data)

    {status, value}
  end

  def decode(data) do
    {status, value, _} = Resp.Decode.decode(data)

    {status, value}
  end

  def encode(value) do
    case value do
      nil ->
        "$-1\r\n"

      :null_array ->
        "*-1\r\n"

      {:simple, message} ->
        "+" <> message <> "\r\n"

      {:error, message} ->
        "-" <> message <> "\r\n"

      {:file, binary} ->
        "$" <> Integer.to_string(byte_size(binary)) <> "\r\n" <> binary

      binary when is_binary(binary) ->
        "$" <> Integer.to_string(byte_size(binary)) <> "\r\n" <> binary <> "\r\n"

      number when is_number(number) ->
        ":" <> Integer.to_string(number) <> "\r\n"

      tuple when is_tuple(tuple) ->
        Tuple.to_list(tuple)
        |> encode()

      map when is_map(map) ->
        map
        |> Enum.flat_map(&Tuple.to_list/1)
        |> encode()

      list when is_list(list) ->
        "*" <> Integer.to_string(length(list)) <> "\r\n" <> Enum.map_join(list, "", &encode/1)

      _ ->
        raise ArgumentError, "Unsupported type for RESP encoding: #{inspect(value)}"
    end
  end
end
