defmodule Relix.Connection.Transaction do
  alias Relix.CommandDispatcher
  alias Relix.CommandContext

  defstruct queue: :queue.new()

  def new() do
    %__MODULE__{}
  end

  def queue(%__MODULE__{queue: queue} = transaction, command, data) do
    queue = :queue.in({command, data}, queue)

    %{transaction | queue: queue}
  end

  def exec(%__MODULE__{queue: queue} = _) do
    ctx = %CommandContext{
      transaction: nil,
      subscribed: false,
      authenticated: true
    }

    commands = :queue.to_list(queue)

    commands
    |> Enum.map(fn {command, data} ->
      CommandDispatcher.dispatch(command, data, ctx)
    end)
    |> Enum.map(fn {reply, _} -> reply end)
  end
end
