defmodule Server do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Server.listen() end}], strategy: :one_for_one)
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    IO.puts("oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo ")

    {:ok, socket} = :gen_tcp.listen(6379, [:binary, active: true, reuseaddr: true])

    IO.puts("Server initialized")
    IO.puts("Ready to accept connections tcp")

    {:ok, _client} = :gen_tcp.accept(socket)

    # handles single connection
    process()
  end

  def process() do
    receive do
      {:tcp, client, _data} ->
        :gen_tcp.send(client, "+PONG\r\n")
        process()

      {:tcp_closed, _client} ->
        IO.puts("Connection closed")

      {:tcp_error, _client, reason} ->
        IO.puts("Error: #{reason}")
    end
  end
end

defmodule CLI do
  def main(_args) do
    {:ok, _pid} = Application.ensure_all_started(:relix)

    # Run forever
    Process.sleep(:infinity)
  end
end
