defmodule Relix.Commands.Publish do
  def dispatch([channel, message]) do
    Relix.Connection.Subscription.publish(channel, message)
  end
end
