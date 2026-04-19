defmodule Relix.Acl do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_user(username) do
    GenServer.call(__MODULE__, {:get_user, username})
  end

  def set_user(username, user) do
    GenServer.cast(__MODULE__, {:set_user, username, user})
  end

  def init(_) do
    default_user =
      case Application.get_env(:relix, :requirepass) do
        nil -> %Relix.Acl.User{nopass: true}
        pass -> Relix.Acl.User.add_password(%Relix.Acl.User{}, pass)
      end

    {:ok, %{"default" => default_user}}
  end

  def handle_call({:get_user, username}, _from, users) do
    {:reply, Map.get(users, username), users}
  end

  def handle_cast({:set_user, username, user}, users) do
    {:noreply, Map.put(users, username, user)}
  end
end
