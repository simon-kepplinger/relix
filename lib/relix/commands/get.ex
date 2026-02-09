defmodule Relix.Commands.Get do
  def dispatch([key]) do
    resp =
      Relix.Store.get(key)
      |> Relix.Resp.encode()

    {:reply, resp}
  end
end
