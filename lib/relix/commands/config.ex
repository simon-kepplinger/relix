defmodule Relix.Commands.Config do
  def dispatch([op | args]) do
    op(String.upcase(op), args)
  end

  def op("GET", [key]) do
    val = Relix.Config.get(String.to_existing_atom(key))

    [key, val]
  end
end
