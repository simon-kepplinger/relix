defmodule Relix.CommandDispatcher do
  require Logger

  alias Relix.Connection.Transaction

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
  alias Relix.Commands.Multi
  alias Relix.Commands.Discard
  alias Relix.Commands.Exec
  alias Relix.Commands.Info
  alias Relix.Commands.Replconf
  alias Relix.Commands.Psync

  # parse and encode commands
  def dispatch([command | data], transaction) do
    command = String.upcase(command)

    Logger.debug("dispatch #{command}")
    {reply, transaction} = dispatch(command, data, transaction)

    {:reply, reply, transaction}
  end

  def dispatch("MULTI", _, transaction) do
    Multi.dispatch(transaction)
  end

  def dispatch("EXEC", _, transaction) do
    Exec.dispatch(transaction)
  end

  def dispatch("DISCARD", _, transaction) do
    Discard.dispatch(transaction)
  end

  def dispatch(command, data, %Transaction{} = transaction) do
    transaction = Transaction.queue(transaction, command, data)

    {{:simple, "QUEUED"}, transaction}
  end

  def dispatch(command, data, nil) do
    reply =
      case command do
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
        "INFO" -> Info.dispatch(data)
        "REPLCONF" -> Replconf.dispatch(data)
        "PSYNC" -> Psync.dispatch(data)
        _ -> {:error, "ERR unknown command #{command}"}
      end

    {reply, nil}
  end
end
