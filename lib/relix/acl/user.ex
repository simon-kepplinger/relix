defmodule Relix.Acl.User do
  defstruct passwords: MapSet.new(), nopass: false

  def add_password(%__MODULE__{} = user, password) do
    passwords = MapSet.put(user.passwords, hash(password))

    %{user | passwords: passwords, nopass: false}
  end

  def authenticate(%__MODULE__{nopass: true}, _password), do: true

  def authenticate(%__MODULE__{passwords: passwords}, password) do
    MapSet.member?(passwords, hash(password))
  end

  defp hash(password) do
    :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)
  end

  def reply(%__MODULE__{passwords: passwords} = user) do
    [
      "flags",
      flags(user),
      "passwords",
      MapSet.to_list(passwords)
    ]
  end

  defp flags(%__MODULE__{nopass: true}), do: ["nopass"]
  defp flags(%__MODULE__{}), do: []
end
