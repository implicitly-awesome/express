defmodule Express.APNS.Supervisor do
  use Supervisor

  alias Express.APNS.Connection
  alias Express.Operations.PoolboyConfigs

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok), do: supervise(children(), opts())

  defp children do
    children =
      [
        supervisor(
          Express.APNS.DelayedPushes,
          [],
          restart: :permanent
        ),
        :poolboy.child_spec(
          PoolboyConfigs.apns_workers().name,
          PoolboyConfigs.apns_workers().config,
          []
        )
      ]

    if Connection.need_ssl_config?() do
      children
    else
      [worker(Express.APNS.JWTHolder, [], restart: :permanent)] ++ children
    end
  end

  defp opts do
    [
      strategy: :one_for_one,
      name: __MODULE__
    ]
  end
end
