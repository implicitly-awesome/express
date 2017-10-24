defmodule Express.PushRequests.ConsumersSupervisor do
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

  def start_consumer do
    Supervisor.start_child(__MODULE__, [])
  end
end
