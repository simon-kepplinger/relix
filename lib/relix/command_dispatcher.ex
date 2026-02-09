defmodule Relix.CommandDispatcher do
  alias Relix.Resp

  def dispatch([command | data]) do
    case String.upcase(command) do
      "PING" -> {:reply, "+PONG\r\n"}
      "ECHO" -> {:reply, Resp.encode(hd(data))}
      _ -> {:reply, "-ERR unknown command\r\n"}
    end
  end
end
