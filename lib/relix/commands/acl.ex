defmodule Relix.Commands.Acl do
  def dispatch([op | args]) do
    op = String.upcase(op)

    op(op, args)
  end

  def op("WHOAMI", _) do
    "default"
  end

  def op("GETUSER", [username]) do
    Relix.Acl.get_user(username)
    |> Relix.Acl.User.reply()
  end

  def op("SETUSER", [username, ">" <> password]) do
    user =
      case Relix.Acl.get_user(username) do
        nil -> %Relix.Acl.User{}
        user -> user
      end

    user = Relix.Acl.User.add_password(user, password)

    Relix.Acl.set_user(username, user)

    {:simple, "OK"}
  end
end
