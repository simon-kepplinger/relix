defmodule Relix.Resp do
  alias Relix.Resp

  def decode(data) do
    {:ok, value, _} = Resp.Decode.decode(data)

    {:ok, value}
  end

  def encode(value) do
    case value do
      nil ->
        "$-1\r\n"

      :null_array ->
        "*-1\r\n"

      list when is_list(list) ->
        "*" <> Integer.to_string(length(list)) <> "\r\n" <> Enum.map_join(list, "", &encode/1)

      {:simple, message} ->
        "+" <> message <> "\r\n"

      binary when is_binary(binary) ->
        "$" <> Integer.to_string(byte_size(binary)) <> "\r\n" <> binary <> "\r\n"

      number when is_number(number) ->
        ":" <> Integer.to_string(number) <> "\r\n"

      {:error, message} ->
        "-" <> message <> "\r\n"

      _ ->
        raise ArgumentError, "Unsupported type for RESP encoding: #{inspect(value)}"
    end
  end
end
