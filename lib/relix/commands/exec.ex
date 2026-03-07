defmodule Relix.Commands.Exec do
  alias Relix.Connection.Transaction

  def dispatch(nil) do
    {{:error, "ERR EXEC without MULTI"}, nil}
  end

  def dispatch(%Transaction{} = transaction) do
    reply = Transaction.exec(transaction)

    {reply, nil}
  end
end
