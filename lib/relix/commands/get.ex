defmodule Relix.Commands.Get do
  def dispatch([key]) do
    Relix.Store.get(key)
  end
end
