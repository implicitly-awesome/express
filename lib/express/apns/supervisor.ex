defmodule Express.APNS.Supervisor do
  use Supervisor

  alias Express.APNS.Connection

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
          apns_workers_pool_name(),
          apns_workers_poolboy_config(),
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

  @spec apns_workers_poolboy_config() :: Keyword.t
  def apns_workers_poolboy_config do
    Application.get_env(:express, :apns)[:workers_poolboy_config] ||
    [
      {:name, {:local, :apns_workers_pool}},
      {:worker_module, Express.APNS.Worker},
      {:size, System.schedulers_online()}
    ]
  end

  @spec apns_workers_pool_name() :: atom()
  def apns_workers_pool_name do
    [{:name, {_, name}} | _] = apns_workers_poolboy_config()
    name
  end
end
