defmodule Relix.Connection.Subscription do
  @registry Relix.PubSub.Registry

  def channels do
    Registry.keys(@registry, self())
  end

  def count do
    channels() |> length()
  end

  def publish(channel, message) do
    Registry.dispatch(@registry, channel, fn entries ->
      entries
      |> Enum.map(fn {pid, _} -> pid end)
      |> Enum.each(&send(&1, {:pubsub_message, channel, message}))
    end)

    Registry.lookup(@registry, channel) |> length()
  end

  def subscribe(channel) do
    Registry.register(@registry, channel, nil)

    count = count()

    if count == 1 do
      send(self(), :subscribe)
    end

    count
  end

  def unsubscribe(channel) do
    Registry.unregister(@registry, channel)

    count = count()

    if count == 0 do
      send(self(), :unsubscribe)
    end

    count
  end
end
