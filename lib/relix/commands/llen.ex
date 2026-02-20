defmodule Relix.Commands.Llen do
  def dispatch([key]) do
    case Relix.Store.get(key) do
      {:list, len, _} -> len
      _ -> 0
    end
  end
end
