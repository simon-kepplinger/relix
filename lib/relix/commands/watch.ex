defmodule Relix.Commands.Watch do
  def dispatch(keys) do
    keys
    |> Enum.each(&Relix.Keyspace.Watch.watch(&1, self()))

    {:simple, "OK"}
  end
end
