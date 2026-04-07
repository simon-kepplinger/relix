defmodule Relix.Rdb.Handler do
  alias Relix.Commands.Set

  def handle({:string, {key, value}}) do
    Set.dispatch([key, value])
  end

  def handle({:exp_ms, exp_ms, {:string, {key, value}}}) do
    now = System.system_time(:millisecond)

    Set.dispatch([key, value, "PX", Integer.to_string(exp_ms - now)])
  end

  def handle({:exp_s, exp_s, {:string, {key, value}}}) do
    now = System.system_time(:second)

    Set.dispatch([key, value, "EX", Integer.to_string(exp_s - now)])
  end
end
