defmodule Express.Application do
  @moduledoc "Sets up Express's supervision tree."

  use Application

  alias Express.Network.HTTP2.{ChatterboxClient, Connection}
  alias Express.Operations.EstablishHTTP2Connection
  alias Express.APNS.SSLConfig

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    do_start(Mix.env())
  end

  @spec do_start(atom()) :: {:ok, pid} |
                            :ignore |
                            {:error, {:already_started, pid()} |
                                      {:shutdown, any()} |
                                      any()}
  defp do_start(:test) do
    opts = [
      strategy: :one_for_one,
      name: Express.Supervisor
    ]

    Supervisor.start_link([], opts)
  end
  defp do_start(_) do
    children = [
      :poolboy.child_spec(apns_pool_name(),
                          apns_poolboy_config(),
                          [apns_http2_connection(), Express.APNS.Worker]),
      :poolboy.child_spec(fcm_pool_name(),
                          fcm_poolboy_config(),
                          Express.FCM.Worker)
    ]

    opts = [
      strategy: :one_for_one,
      name: Express.Supervisor
    ]

    Supervisor.start_link(children, opts)
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
      {:name, {:local, :apns_supervisors_pool}},
      {:worker_module, Express.APNS.Supervisor},
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
      {:name, {:local, :fcm_supervisors_pool}},
      {:worker_module, Express.FCM.Supervisor},
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

  @spec apns_http2_connection :: Connection.t | nil
  defp apns_http2_connection do
    params = [
      http2_client: ChatterboxClient,
      ssl_config: SSLConfig.new()
    ]

    case EstablishHTTP2Connection.run(params) do
      {:ok, connection} -> connection
      _ -> nil
    end
  end
end
