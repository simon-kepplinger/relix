defmodule Relix.Commands.Discard do
  def dispatch(nil) do
    {{:error, "ERR DISCARD without MULTI"}, nil}
  end

  def dispatch(_) do
    {{:simple, "OK"}, nil}
  end
end
