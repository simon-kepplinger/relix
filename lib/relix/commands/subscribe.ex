defmodule Relix.Commands.Subscribe do
  def dispatch([channel]) do
    count = Relix.Connection.Subscription.subscribe(channel)

    ["subscribe", channel, count]
  end
end
