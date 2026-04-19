defmodule Relix.Commands.Auth do
  def dispatch([username, password]) do
    user = Relix.Acl.get_user(username)

    case Relix.Acl.User.authenticate(user, password) do
      true -> {:simple, "OK"}
      false -> {:error, "WRONGPASS invalid username-password pair or user is disabled."}
    end
  end
end
