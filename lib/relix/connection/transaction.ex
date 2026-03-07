defmodule Relix.Connection.Transaction do
  alias Relix.CommandDispatcher

  defstruct queue: :queue.new()

  def new() do
    %__MODULE__{}
  end

  def queue(%__MODULE__{queue: queue} = transaction, command, data) do
    queue = :queue.in({command, data}, queue)

    %{transaction | queue: queue}
  end

  def exec(%__MODULE__{queue: queue} = _) do
    commands = :queue.to_list(queue)

    commands
    |> Enum.map(fn {command, data} ->
      CommandDispatcher.dispatch(command, data, nil)
    end)
    |> Enum.map(fn {reply, _} -> reply end)
  end
end
