defmodule Relix.CommandDispatcher do
  require Logger

  alias Relix.Resp
  alias Relix.Commands.Ping
  alias Relix.Commands.Echo
  alias Relix.Commands.Set
  alias Relix.Commands.Get
  alias Relix.Commands.Lrange
  alias Relix.Commands.Lpush
  alias Relix.Commands.Llen
  alias Relix.Commands.Lpop
  alias Relix.Commands.Blpop
  alias Relix.Commands.Type
  alias Relix.Commands.Xadd
  alias Relix.Commands.Xrange
  alias Relix.Commands.Xread
  alias Relix.Commands.Incr

  def dispatch([command | data]) do
    Logger.debug("dispatch #{command}")

    reply =
      case String.upcase(command) do
        "PING" -> Ping.dispatch()
        "ECHO" -> Echo.dispatch(data)
        "SET" -> Set.dispatch(data)
        "GET" -> Get.dispatch(data)
        "RPUSH" -> Lpush.dispatch(:right, data)
        "LPUSH" -> Lpush.dispatch(:left, data)
        "LRANGE" -> Lrange.dispatch(data)
        "LLEN" -> Llen.dispatch(data)
        "LPOP" -> Lpop.dispatch(data)
        "BLPOP" -> Blpop.dispatch(data)
        "TYPE" -> Type.dispatch(data)
        "XADD" -> Xadd.dispatch(data)
        "XRANGE" -> Xrange.dispatch(data)
        "XREAD" -> Xread.dispatch(data)
        "INCR" -> Incr.dispatch(data)
        _ -> {:error, "ERR unknown command #{command}"}
      end

    {:reply, Resp.encode(reply)}
  end
end
