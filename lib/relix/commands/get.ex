defmodule Relix.Commands.Get do
  def dispatch([key]) do
    case Relix.Store.get(key) do
      {_, value} -> value
      _ -> nil
    end
  end
end
