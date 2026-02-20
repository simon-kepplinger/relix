defmodule Relix.Commands.Ping do
  def dispatch() do
    {:simple, "PONG"}
  end
end
