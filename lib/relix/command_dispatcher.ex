defmodule Relix.CommandDispatcher do
  require Logger

  alias Relix.Commands.Ping
  alias Relix.Commands.Echo
  alias Relix.Commands.Set
  alias Relix.Commands.Get

  def dispatch([command | data]) do
    Logger.debug("dispatch #{command}")

    case String.upcase(command) do
      "PING" -> Ping.dispatch()
      "ECHO" -> Echo.dispatch(data)
      "SET" -> Set.dispatch(data)
      "GET" -> Get.dispatch(data)
      _ -> {:reply, "-ERR unknown command '#{command}\r\n"}
    end
  end
end
