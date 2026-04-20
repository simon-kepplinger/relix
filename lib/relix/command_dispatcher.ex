defmodule Relix.CommandContext do
  defstruct [:transaction, subscribed: false, authenticated: false, dirty_watch: false]
end

defmodule Relix.CommandDispatcher do
  require Logger

  alias Relix.Connection.Transaction
  alias Relix.CommandContext

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
  alias Relix.Commands.Wait
  alias Relix.Commands.Config
  alias Relix.Commands.Keys
  alias Relix.Commands.Subscribe
  alias Relix.Commands.Unsubscribe
  alias Relix.Commands.Publish
  alias Relix.Commands.Zadd
  alias Relix.Commands.Zrank
  alias Relix.Commands.Zrange
  alias Relix.Commands.Zscore
  alias Relix.Commands.Zrem
  alias Relix.Commands.Zcard
  alias Relix.Commands.Geoadd
  alias Relix.Commands.Geopos
  alias Relix.Commands.Geodist
  alias Relix.Commands.Geosearch
  alias Relix.Commands.Auth
  alias Relix.Commands.Acl
  alias Relix.Commands.Watch
  alias Relix.Commands.Unwatch

  @write_commands ~w(SET DEL INCR DECR LPUSH RPUSH LPOP BLPOP XADD ZADD ZREM GEOADD)

  def write_command?(command) do
    String.upcase(command) in @write_commands
  end

  # parse and encode commands
  def dispatch([command | data], %CommandContext{} = ctx) do
    command = String.upcase(command)

    Logger.debug("dispatch #{command}")

    {reply, transaction} = dispatch(command, data, ctx)

    {:reply, command, reply, transaction}
  end

  # only allow AUTH if not authenticated
  def dispatch("AUTH", data, %CommandContext{authenticated: false}) do
    {Auth.dispatch(data), nil}
  end

  # on unauthenticated
  def dispatch(_, _, %CommandContext{authenticated: false}) do
    {{:error, "NOAUTH Authentication required."}, nil}
  end

  # execute commands in subscribed mode
  def dispatch(command, data, %CommandContext{subscribed: true}) do
    reply =
      case command do
        "PING" -> Ping.dispatch()
        "SUBSCRIBE" -> Subscribe.dispatch(data)
        "UNSUBSCRIBE" -> Unsubscribe.dispatch(data)
        "PUBLISH" -> Publish.dispatch(data)
        _ -> {:error, "ERR Can't execute '#{command}' in subscribed mode"}
      end

    # special encode in subscribed mode
    reply =
      case reply do
        {:simple, res} -> [String.downcase(res), ""]
        res -> res
      end

    {reply, nil}
  end

  # EXEC on dirty watch should fail
  def dispatch("EXEC", _, %CommandContext{dirty_watch: true}) do
    Unwatch.dispatch()
    {:null_array, nil}
  end

  # transaction control commands
  def dispatch("MULTI", _, %CommandContext{transaction: transaction}) do
    Multi.dispatch(transaction)
  end

  def dispatch("EXEC", _, %CommandContext{transaction: transaction}) do
    Unwatch.dispatch()
    Exec.dispatch(transaction)
  end

  def dispatch("DISCARD", _, %CommandContext{transaction: transaction}) do
    Unwatch.dispatch()
    Discard.dispatch(transaction)
  end

  def dispatch("WATCH", _, %CommandContext{transaction: %Transaction{} = transaction}) do
    {{:error, "ERR WATCH inside MULTI is not allowed"}, transaction}
  end

  # queue commands to a transaction
  def dispatch(command, data, %CommandContext{transaction: %Transaction{} = transaction}) do
    transaction = Transaction.queue(transaction, command, data)

    {{:simple, "QUEUED"}, transaction}
  end

  # execute commands
  def dispatch(command, data, %CommandContext{}) do
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
        "WAIT" -> Wait.dispatch(data)
        "CONFIG" -> Config.dispatch(data)
        "KEYS" -> Keys.dispatch(data)
        "SUBSCRIBE" -> Subscribe.dispatch(data)
        "UNSUBSCRIBE" -> Unsubscribe.dispatch(data)
        "PUBLISH" -> Publish.dispatch(data)
        "ZADD" -> Zadd.dispatch(data)
        "ZRANK" -> Zrank.dispatch(data)
        "ZRANGE" -> Zrange.dispatch(data)
        "ZSCORE" -> Zscore.dispatch(data)
        "ZREM" -> Zrem.dispatch(data)
        "ZCARD" -> Zcard.dispatch(data)
        "GEOADD" -> Geoadd.dispatch(data)
        "GEOPOS" -> Geopos.dispatch(data)
        "GEODIST" -> Geodist.dispatch(data)
        "GEOSEARCH" -> Geosearch.dispatch(data)
        "AUTH" -> Auth.dispatch(data)
        "ACL" -> Acl.dispatch(data)
        "WATCH" -> Watch.dispatch(data)
        "UNWATCH" -> Unwatch.dispatch()
        _ -> {:error, "ERR unknown command #{command}"}
      end

    Relix.Keyspace.Watch.notify_write(command, data)
    Relix.Replication.Master.propagate([command | data])
    Relix.Aof.write([command | data])

    {reply, nil}
  end
end
