defmodule Express.FCM.Supervisor do
  @moduledoc "Sets up FCM supervision tree."

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, {:ok, Mix.env()}, name: __MODULE__)
  end

  def init({:ok, :test}), do: supervise([], opts())
  def init({:ok, _}), do: supervise(children(), opts())

  defp children do
    [
      supervisor(Express.FCM.DelayedPushes, [], restart: :permanent),
      # worker(Express.FCM.MessagesBuffer, [], restart: :permanent),
      :poolboy.child_spec(fcm_pool_name(), fcm_poolboy_config(), [])
    ]
  end

  defp opts do
    [
      strategy: :one_for_one,
      name: Express.Supervisor
    ]
  end

  @doc """
  Returns poolboy config of FCM supervisors pool.
  If poolboy config was overriden in config.exs - returns it,
  default config will be returned otherwise.
  """
  @spec fcm_poolboy_config() :: Keyword.t
  def fcm_poolboy_config do
    Application.get_env(:express, :fcm)[:poolboy] ||
    [
      {:name, {:local, :fcm_workers_pool}},
      {:worker_module, Express.FCM.Worker},
      {:size, 5},
      {:max_overflow, 1}
    ]
  end

  @doc "Returns the name of the FCM supervisors pool."
  @spec fcm_pool_name() :: atom()
  def fcm_pool_name do
    [{:name, {_, name}} | _] = fcm_poolboy_config()
    name
  end
end
