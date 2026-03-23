defmodule Relix.Commands.Keys do
  def dispatch(_) do
    Relix.Store.keys()
  end
end
