defmodule Express.FCM.Supervisor do
  use Supervisor

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
        fcm_workers_pool_name(),
        fcm_workers_poolboy_config(),
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

  def fcm_workers_poolboy_config do
    Application.get_env(:express, :fcm)[:workers_poolboy_config] ||
    [
      {:name, {:local, :fcm_workers_pool}},
      {:worker_module, Express.FCM.Worker},
      {:size, System.schedulers_online()}
    ]
  end

  def fcm_workers_pool_name do
    [{:name, {_, name}} | _] = fcm_workers_poolboy_config()
    name
  end
end
