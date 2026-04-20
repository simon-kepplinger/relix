defmodule Relix.Aof do
  use GenServer

  alias Relix.Config

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def write([key | _] = command) do
    pid = Process.whereis(__MODULE__)

    with true <- Relix.CommandDispatcher.write_command?(key),
         true <- pid != nil and pid != self() do
      GenServer.call(pid, {:write, Relix.Resp.encode(command)})
    end
  end

  def init(_) do
    manifest_path = ensure_files()
    %{filename: filename} = read_manifest(manifest_path)
    aof_path = to_aof_path(filename)

    Relix.Aof.Replay.replay(aof_path)

    {:ok, file} = File.open(aof_path, [:append])
    {:ok, %{file: file, appendfsync: Config.get(:appendfsync)}}
  end

  def terminate(_reason, %{file: file}) do
    File.close(file)
  end

  def handle_call({:write, command}, _from, %{file: file, appendfsync: "always"} = state) do
    IO.write(file, command)
    :file.sync(file)

    {:reply, :ok, state}
  end

  def handle_call({:write, command}, _from, %{file: file} = state) do
    IO.write(file, command)
    {:reply, :ok, state}
  end

  defp read_manifest(manifest_path) do
    manifest_path
    |> File.read!()
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&parse_manifest_line/1)
    |> List.first()
  end

  defp to_aof_path(filename) do
    Config.get(:dir)
    |> Path.join(Config.get(:appenddirname))
    |> Path.join(filename)
  end

  defp parse_manifest_line(line) do
    [_, filename, _, seq_str, _, type] = String.split(line)
    %{filename: filename, seq: String.to_integer(seq_str), type: type}
  end

  defp ensure_files do
    base_dir = Config.get(:dir)
    dirname = Config.get(:appenddirname)
    filename = Config.get(:appendfilename)

    dir = Path.join(base_dir, dirname)
    aof_filename = "#{filename}.1.incr.aof"
    path = Path.join(dir, aof_filename)
    manifest_path = Path.join(dir, "#{filename}.manifest")

    File.mkdir_p!(dir)

    unless File.exists?(path) do
      File.write!(path, "")
    end

    unless File.exists?(manifest_path) do
      File.write!(manifest_path, "file #{aof_filename} seq 1 type i")
    end

    manifest_path
  end
end
