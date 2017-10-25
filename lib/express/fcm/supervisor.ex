defmodule Express.FCM.Supervisor do
  use Supervisor

  alias Express.Operations.PoolboyConfigs

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok), do: supervise(children(), opts())

  defp children do
    [
      supervisor(
        Express.FCM.DelayedPushes,
        [],
        restart: :permanent
      ),
      :poolboy.child_spec(
        PoolboyConfigs.fcm_workers().name,
        PoolboyConfigs.fcm_workers().config,
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
