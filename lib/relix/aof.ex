defmodule Relix.Aof do
  alias Relix.Config

  def ensure do
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

    path
  end
end
