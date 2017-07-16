defmodule Express.Application do
  @moduledoc false

  use Application

  alias Express.Network.HTTP2
  alias Express.APNS

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
      :poolboy.child_spec(apns_pool_name(), apns_poolboy_config(), {
        HTTP2.ChatterboxClient,
        APNS.SSLConfig.new()
      }),
      :poolboy.child_spec(fcm_pool_name(), fcm_poolboy_config(), [])
    ]

    opts = [
      strategy: :one_for_one,
      name: Express.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end

  @spec apns_poolboy_config() :: Keyword.t
  def apns_poolboy_config do
    Application.get_env(:express, :apns)[:poolboy]
  end

  @spec apns_pool_name() :: atom()
  def apns_pool_name do
    [{:name, {_, name}} | _] = apns_poolboy_config()
    name
  end

  @spec fcm_poolboy_config() :: Keyword.t
  def fcm_poolboy_config, do: Application.get_env(:express, :fcm)[:poolboy]

  @spec fcm_pool_name() :: atom()
  def fcm_pool_name do
    [{:name, {_, name}} | _] = fcm_poolboy_config()
    name
  end
end
