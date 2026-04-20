defmodule Relix.Aof.Replay do
  require Logger

  def replay(file) do
    if File.exists?(file) do
      file |> File.read!() |> replay_data()
    end
  end

  defp replay_data(""), do: :ok

  defp replay_data(data) do
    Logger.info("Replaying AOF")

    {:ok, commands} = Relix.Resp.decode_all(data)

    ctx = %Relix.CommandContext{authenticated: true}

    commands
    |> Enum.map(fn {command, _} -> command end)
    |> Enum.each(&Relix.CommandDispatcher.dispatch(&1, ctx))
  end
end
