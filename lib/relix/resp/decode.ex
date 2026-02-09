defmodule Relix.Resp.Decode do
  @crlf "\r\n"

  # bulk strings
  def decode("$" <> bulk_string) do
    {length_str, data} = read_line(bulk_string)

    case :erlang.binary_to_integer(length_str) do
      -1 ->
        {:ok, nil, data}

      length when length >= 0 ->
        <<value::binary-size(^length), @crlf, rest::binary>> = data
        {:ok, value, rest}
    end
  end

  # arrays 
  def decode("*" <> array) do
    {count_str, data} = read_line(array)

    case :erlang.binary_to_integer(count_str) do
      -1 ->
        {:ok, nil, data}

      0 ->
        {:ok, [], data}

      count when count > 0 ->
        decode_array(data, count)
    end
  end

  def decode_array(data, count, acc \\ [])

  def decode_array(data, 0, acc) do
    {:ok, Enum.reverse(acc), data}
  end

  def decode_array(data, count, acc) do
    {:ok, value, rest} = decode(data)

    decode_array(rest, count - 1, [value | acc])
  end

  # read next line
  def read_line(data) do
    case :binary.split(data, @crlf) do
      [line, rest] -> {line, rest}
      [line] -> {line, :eof}
    end
  end
end
