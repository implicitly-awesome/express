defmodule Express.PushRequests.Supervisor do
  use Supervisor

  alias Express.Operations.PoolboyConfigs

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok), do: supervise(children(), opts())

  defp children do
    [
      supervisor(
        Express.PushRequests.ConsumersSupervisor,
        [],
        restart: :permanent
      ),
      worker(
        Express.PushRequests.Buffer,
        [],
        restart: :permanent,
        name: Express.PushRequests.Buffer
      ),
      :poolboy.child_spec(
        PoolboyConfigs.buffer_adders().name,
        PoolboyConfigs.buffer_adders().config,
        []
      )
    ]
  end

  defp opts do
    [
      strategy: :one_for_one,
      name: __MODULE__
    ]
  end
end
