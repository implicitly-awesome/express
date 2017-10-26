defmodule Express.PushRequests.ConsumersSupervisor do
  @moduledoc """
  Dynamically spawns and supervises consumers for the push requests buffer.
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok), do: supervise(children(), opts())

  defp children do
    [
      worker(
        Express.PushRequests.Consumer,
        [],
        restart: :permanent
      )
    ]
  end

  defp opts do
    [strategy: :simple_one_for_one, name: __MODULE__]
  end

  @doc "Spawns the buffer consumer."
  @spec start_consumer() :: Supervisor.on_start_child
  def start_consumer do
    Supervisor.start_child(__MODULE__, [])
  end
end
