defmodule Relix.Keyspace.Serializer do
  use GenServer

  @moduledoc """
  A dedicated GenServer for serializing operations within a specific keyspace.
  """

  defstruct key: nil, waiting: :queue.new()

  # idle out processes to free up resources when not in use
  @idle_timeout 30_000

  ## Client

  def run(key, fun) do
    pid = get_or_start(key)
    GenServer.call(pid, {:run, fun})
  end

  def start_link(key) do
    GenServer.start_link(__MODULE__, key, name: {:via, Registry, {Relix.Keyspace.Registry, key}})
  end

  ## Server

  def init(key) do
    {:ok, %__MODULE__{key: key}, @idle_timeout}
  end

  def handle_call({:run, fun}, _from, state) do
    result = fun.()
    {:reply, result, state, @idle_timeout}
  end

  # TODO create something like ":timeout_run" info which would timeout waiters

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  ## Private

  defp get_or_start(key) do
    case Registry.lookup(Relix.Keyspace.Registry, key) do
      [{pid, _}] -> pid
      [] -> start(key)
    end
  end

  defp start(key) do
    case DynamicSupervisor.start_child(Relix.Keyspace.Supervisor, {__MODULE__, key}) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end
end
