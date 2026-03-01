defmodule Relix.Commands.Type do
  def dispatch([key]) do
    case Relix.Store.get(key) do
      nil -> {:simple, "none"}
      {type, _} -> {:simple, to_string(type)}
    end
  end
end
