defmodule Relix.Commands.Unwatch do
  def dispatch() do
    Relix.Keyspace.Watch.unwatch(self())

    {:simple, "OK"}
  end
end
