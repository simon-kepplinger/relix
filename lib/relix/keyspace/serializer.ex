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
    GenServer.call(pid, {:run, fun}, :infinity)
  end

  def start_link(key) do
    GenServer.start_link(__MODULE__, key, name: {:via, Registry, {Relix.Keyspace.Registry, key}})
  end

  ## Server

  def init(key) do
    {:ok, %__MODULE__{key: key}, @idle_timeout}
  end

  def handle_call({:run, fun}, from, state) do
    consume = fn values ->
      {values, n, _} = push_to_waiters(values, state.waiting)
      {values, n}
    end

    case fun.(consume) do
      # add process to waiter queue
      {:wait, timeout_ms, reply_fn} ->
        if timeout_ms != 0,
          do: Process.send_after(self(), {:timeout_waiter, from, reply_fn}, timeout_ms)

        waiting = :queue.in({from, reply_fn}, state.waiting)
        {:noreply, %{state | waiting: waiting}, @idle_timeout}

      result ->
        {:reply, result, state, @idle_timeout}
    end
  end

  # automatic cleanup of serializer processes 
  def handle_info(:timeout, %{waiting: waiting} = state) do
    case :queue.is_empty(waiting) do
      true ->
        {:stop, :normal, state}

      false ->
        # Still have waiters — stay alive, check again later
        {:noreply, state, @idle_timeout}
    end
  end

  # timeout for waiting processes -> remove from queue
  def handle_info({:timeout_waiter, from, reply_fn}, state) do
    waiting = :queue.filter(fn {f, _} -> f != from end, state.waiting)

    GenServer.reply(from, reply_fn.(:timeout))

    {:noreply, %{state | waiting: waiting}, @idle_timeout}
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

  defp push_to_waiters(values, waiting), do: push_to_waiters(values, 0, waiting)

  defp push_to_waiters([], n, waiting), do: {[], n, waiting}

  defp push_to_waiters(values, n, waiting) do
    case :queue.out(waiting) do
      {:empty, _} ->
        {values, n, waiting}

      {{:value, {from, reply_fn}}, waiting} ->
        [value | rest] = values
        GenServer.reply(from, reply_fn.(value))
        push_to_waiters(rest, n + 1, waiting)
    end
  end
end
