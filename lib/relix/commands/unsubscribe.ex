defmodule Relix.Commands.Unsubscribe do
  def dispatch([channel]) do
    count = Relix.Connection.Subscription.unsubscribe(channel)

    ["unsubscribe", channel, count]
  end
end
