defmodule Relix.Commands.Echo do
  def dispatch([data]) do
    {:reply, Relix.Resp.encode(data)}
  end
end
