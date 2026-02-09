defmodule Relix.Commands.Set do
  def dispatch([key, value]) do
    true = Relix.Store.set(key, value)

    ack()
  end

  def dispatch([key, value, command, arg]) do
    dispatch([key, value], [String.upcase(command), arg])
  end

  def dispatch([key, value], ["PX", ms_str]) do
    milliseconds = :erlang.binary_to_integer(ms_str)
    true = Relix.Store.set(key, value, milliseconds)

    ack()
  end

  def dispatch([key, value], ["EX", s_str]) do
    seconds = :erlang.binary_to_integer(s_str)
    true = Relix.Store.set(key, value, seconds * 1_000)

    ack()
  end

  defp ack() do
    {:reply, "+OK\r\n"}
  end
end
