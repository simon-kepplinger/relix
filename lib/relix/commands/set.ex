defmodule Relix.Commands.Set do
  def dispatch([key, value]) do
    true = Relix.Store.set(key, value)

    {:reply, "+OK\r\n"}
  end
end
