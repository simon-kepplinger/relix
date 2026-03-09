defmodule Relix.Commands.Replconf do
  def dispatch(_) do
    {:simple, "OK"}
  end
end
