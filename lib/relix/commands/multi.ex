defmodule Relix.Commands.Multi do
  alias Relix.Connection.Transaction

  def dispatch(nil) do
    {{:simple, "OK"}, Transaction.new()}
  end

  def dispatch(%Transaction{} = transaction) do
    {{:error, "ERR MULTI calls can not be nested"}, transaction}
  end
end
