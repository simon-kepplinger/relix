defmodule Relix.Rdb do
  alias Relix.Rdb.Consumer

  defstruct stream: nil

  def new(stream) do
    %__MODULE__{stream: stream}
  end

  def process(%__MODULE__{stream: stream}) do
    stream
    |> Enum.reduce(Consumer.new(), &Consumer.consume(&2, &1))
  end
end
