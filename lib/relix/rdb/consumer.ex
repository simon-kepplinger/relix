defmodule Relix.Rdb.Consumer do
  alias Relix.Rdb

  defstruct buffer: "", checksum: nil, eof: false, db: false

  def new do
    %__MODULE__{}
  end

  # ignore until db section is reached
  def consume(%__MODULE__{buffer: buffer, db: false} = rdb, chunk) do
    chunk = buffer <> chunk

    case :binary.match(chunk, <<0xFE>>) do
      {pos, 1} ->
        <<_dropped::binary-size(^pos), rest::binary>> = chunk
        consume(%__MODULE__{rdb | buffer: <<>>, db: true}, rest)

      :nomatch ->
        %__MODULE__{rdb | buffer: <<>>}
    end
  end

  # consume data
  def consume(%__MODULE__{buffer: buffer, db: true} = rdb, chunk) do
    chunk = buffer <> chunk

    case parse(chunk) do
      {:data, data, rest} ->
        Rdb.Handler.handle(data)
        consume(%{rdb | buffer: <<>>}, rest)

      {:eof, checksum} ->
        %__MODULE__{rdb | checksum: checksum, eof: true}

      {_, _, rest} ->
        consume(%{rdb | buffer: <<>>}, rest)

      :incomplete ->
        %__MODULE__{rdb | buffer: chunk}
    end
  end

  # db
  defp parse(<<0xFE, rest::binary>>) do
    with {:ok, data, rest} <- read_size_encoded(rest) do
      {:db, data, rest}
    end
  end

  # resizedb
  defp parse(<<0xFB, rest::binary>>) do
    with {:ok, db_size, rest} <- read_size_encoded(rest),
         {:ok, exp_size, rest} <- read_size_encoded(rest) do
      {:resizedb, {db_size, exp_size}, rest}
    end
  end

  # exp (ms)
  defp parse(<<0xFC, exp_ms::64-unsigned-little, rest::binary>>) do
    with {:data, {type, value}, rest} <- read_data(rest) do
      {:data, {:exp_ms, exp_ms, {type, value}}, rest}
    end
  end

  # exp (s)
  defp parse(<<0xFD, exp_s::32-unsigned-little, rest::binary>>) do
    with {:data, {type, value}, rest} <- read_data(rest) do
      {:data, {:exp_s, exp_s, {type, value}}, rest}
    end
  end

  # EOF
  defp parse(<<0xFF, checksum::64>>) do
    {:eof, checksum}
  end

  defp parse(data) do
    read_data(data)
  end

  # string
  defp read_data(<<0x00, rest::binary>>) do
    with {:ok, key, rest} <- read_string(rest),
         {:ok, value, rest} <- read_string(rest) do
      {:data, {:string, {key, value}}, rest}
    end
  end

  defp read_string(<<0xC0, n::8-signed, rest::binary>>),
    do: {:ok, n, rest}

  defp read_string(<<0xC1, n::16-signed-little, rest::binary>>),
    do: {:ok, n, rest}

  defp read_string(<<0xC2, n::32-signed-little, rest::binary>>),
    do: {:ok, n, rest}

  defp read_string(data) do
    with {:ok, length, rest} <- read_size_encoded(data),
         {:ok, string, rest} <- read_binary(length, rest) do
      {:ok, string, rest}
    end
  end

  defp read_size_encoded(<<0b00::2, data::6, rest::binary>>),
    do: {:ok, data, rest}

  defp read_size_encoded(<<0b01::2, data::14, rest::binary>>),
    do: {:ok, data, rest}

  defp read_size_encoded(<<0b10::2, data::30, rest::binary>>),
    do: {:ok, data, rest}

  defp read_size_encoded(_),
    do: :incomplete

  defp read_binary(length, data) when byte_size(data) >= length do
    <<binary::binary-size(^length), rest::binary>> = data
    {:ok, binary, rest}
  end

  defp read_binary(_, _),
    do: :incomplete
end
