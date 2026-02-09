defmodule Relix.Commands.Ping do
  def dispatch() do
    {:reply, "+PONG\r\n"}
  end
end
