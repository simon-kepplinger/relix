defmodule Relix.Commands.Type do
  def dispatch([key]) do
    case Relix.Store.get(key) do
      nil -> {:simple, "none"}
      val -> {:simple, val |> elem(0) |> to_string()}
    end
  end
end
