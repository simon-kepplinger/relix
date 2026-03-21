defmodule Relix.Commands.Replconf do
  def dispatch([op | args]) do
    op(String.upcase(op), args)
  end

  def op("GETACK", _) do
    offset = Relix.Replication.replication_offset()

    ["REPLCONF", "ACK", to_string(offset)]
  end

  def op(_, _) do
    {:simple, "OK"}
  end
end
