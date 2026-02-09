defmodule Mix.Tasks.Relix.Watch do
  use Mix.Task

  @shortdoc "Recompile and rerun Relix when sources change"
  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    Mix.shell().info("[relix.watch] watching for changes (#{Mix.env()})")

    Mix.Task.clear()
    Mix.Task.rerun("compile")

    {:ok, sup} = Task.Supervisor.start_link()
    {:ok, watcher} = FileSystem.start_link(dirs: watch_dirs())
    FileSystem.subscribe(watcher)

    state = %{
      watcher: watcher,
      sup: sup,
      runner: start_runner(sup, args),
      args: args,
      pending_paths: MapSet.new(),
      debounce_ref: nil
    }

    loop(state)
  end

  defp loop(%{watcher: watcher} = state) do
    receive do
      {:file_event, ^watcher, {path, _events}} ->
        loop(schedule_restart(path, state))

      {:file_event, ^watcher, :stop} ->
        Mix.shell().info("[relix.watch] watcher stopped")
        :ok

      :flush_changes ->
        loop(handle_pending(state))

      _other ->
        loop(state)
    end
  end

  defp schedule_restart(path, state) do
    path = IO.chardata_to_string(path)

    if relevant?(path) do
      rel = relative_path(path)
      pending = MapSet.put(state.pending_paths, rel)

      ref =
        case state.debounce_ref do
          nil -> Process.send_after(self(), :flush_changes, 200)
          existing -> existing
        end

      %{state | pending_paths: pending, debounce_ref: ref}
    else
      state
    end
  end

  defp handle_pending(%{pending_paths: pending} = state) do
    if MapSet.size(pending) == 0 do
      %{state | debounce_ref: nil}
    else
      files = pending |> Enum.to_list() |> Enum.sort()
      Mix.shell().info("[relix.watch] changes in #{Enum.join(files, ", ")} — recompiling…")
      Mix.Task.clear()
      Mix.Task.rerun("compile")
      stop_runner(state.runner)

      %{
        state
        | runner: start_runner(state.sup, state.args),
          pending_paths: MapSet.new(),
          debounce_ref: nil
      }
    end
  end

  defp start_runner(sup, args) do
    Task.Supervisor.async_nolink(sup, fn ->
      CLI.main(args)
    end)
  end

  defp stop_runner(task) do
    _ = Application.stop(:relix)
    Task.shutdown(task, :brutal_kill)
  end

  defp relevant?(path) do
    not Enum.any?(ignore_patterns(), &String.contains?(path, &1))
  end

  defp relative_path(path) do
    Path.relative_to(path, File.cwd!())
  rescue
    ArgumentError ->
      path
  end

  defp watch_dirs do
    ["lib", "config", File.cwd!()]
    |> Enum.map(&Path.expand/1)
    |> Enum.uniq()
  end

  defp ignore_patterns do
    ["/_build/", "/deps/", "/.git/", ".elixir_ls"]
  end
end
