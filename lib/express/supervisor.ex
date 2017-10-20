defmodule Express.Supervisor do
  @moduledoc "Sets up Express's supervision tree."

  use Supervisor

  alias Express.Network.HTTP2.{ChatterboxClient, Connection}
  alias Express.Operations.EstablishHTTP2Connection
  alias Express.APNS.{SSLConfig, JWT}

  def start_link do
    Supervisor.start_link(__MODULE__, {:ok, Mix.env()}, name: __MODULE__)
  end

  def init({:ok, :test}), do: supervise([], opts())
  def init({:ok, _}), do: supervise(children(), opts())

  defp children do
    [
      worker(Express.APNS.ConnectionHolder, [], restart: :permanent),
      supervisor(Express.APNS.DelayedPushes, [], restart: :permanent),
      supervisor(Express.FCM.DelayedPushes, [], restart: :permanent),
      :poolboy.child_spec(apns_pool_name(), apns_poolboy_config(), []),
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
  Returns poolboy config of APNS supervisors pool.
  If poolboy config was overriden in config.exs - returns it,
  default config will be returned otherwise.
  """
  @spec apns_poolboy_config() :: Keyword.t
  def apns_poolboy_config do
    Application.get_env(:express, :apns)[:poolboy] ||
    [
      {:name, {:local, :apns_workers_pool}},
      {:worker_module, Express.APNS.Worker},
      {:size, 5},
      {:max_overflow, 1}
    ]
  end

  @doc "Returns the name of the APNS supervisors pool."
  @spec apns_pool_name() :: atom()
  def apns_pool_name do
    [{:name, {_, name}} | _] = apns_poolboy_config()
    name
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
