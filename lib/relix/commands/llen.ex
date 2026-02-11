defmodule Relix.Commands.Llen do
  alias Relix.Resp

  def dispatch([key]) do
    case Relix.Store.get(key) do
      {:list, len, _} -> {:reply, Resp.encode(len)}
      _ -> {:reply, Resp.encode(0)}
    end
  end
end
