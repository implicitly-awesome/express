defmodule Express.Configuration do
  @moduledoc "Defines a behaviour for configuration modules."

  @callback buffer() :: Keyword.t
  @callback apns() :: Keyword.t
  @callback fcm() :: Keyword.t

  defmodule APNS do
    @moduledoc "Defines an API for APNS configuration."

    @spec mode() :: atom()
    def mode do
      Application.get_env(:express, :apns)[:mode] ||
      Application.get_env(:express, :module).apns()[:mode]
    end

    @spec cert_path() :: String.t
    def cert_path do
      Application.get_env(:express, :apns)[:cert_path] ||
      Application.get_env(:express, :module).apns()[:cert_path]
    end

    @spec cert() :: binary()
    def cert do
      Application.get_env(:express, :apns)[:cert] ||
      Application.get_env(:express, :module).apns()[:cert]
    end

    @spec key_path() :: String.t
    def key_path do
      Application.get_env(:express, :apns)[:key_path] ||
      Application.get_env(:express, :module).apns()[:key_path]
    end

    @spec key() :: binary()
    def key do
      Application.get_env(:express, :apns)[:key] ||
      Application.get_env(:express, :module).apns()[:key]
    end

    @spec team_id() :: String.t
    def team_id do
      Application.get_env(:express, :apns)[:team_id] ||
      Application.get_env(:express, :module).apns()[:team_id]
    end

    @spec key_id() :: String.t
    def key_id do
      Application.get_env(:express, :apns)[:key_id] ||
      Application.get_env(:express, :module).apns()[:key_id]
    end

    @spec auth_key_path() :: String.t
    def auth_key_path do
      Application.get_env(:express, :apns)[:auth_key_path] ||
      Application.get_env(:express, :module).apns()[:auth_key_path]
    end

    @spec auth_key() :: binary()
    def auth_key do
      Application.get_env(:express, :apns)[:auth_key] ||
      Application.get_env(:express, :module).apns()[:auth_key]
    end

    @spec workers_pool_config() :: Keyword.t
    def workers_pool_config do
      Application.get_env(:express, :apns)[:workers_pool_config] ||
      Application.get_env(:express, :module).apns()[:workers_pool_config]
    end
  end

  defmodule FCM do
    @moduledoc "Defines an API for FCM configuration."

    @spec api_key() :: String.t
    def api_key do
      Application.get_env(:express, :fcm)[:api_key] ||
      Application.get_env(:express, :module).fcm()[:api_key]
    end

    @spec workers_pool_config() :: Keyword.t
    def workers_pool_config do
      Application.get_env(:express, :fcm)[:workers_pool_config] ||
      Application.get_env(:express, :module).fcm()[:workers_pool_config]
    end
  end

  defmodule Buffer do
    @moduledoc "Defines an API for Buffer configuration."

    @spec adders_pool_config() :: Keyword.t
    def adders_pool_config do
      Application.get_env(:express, :buffer)[:adders_pool_config] ||
      Application.get_env(:express, :module).buffer()[:adders_pool_config]
    end

    @spec max_size() :: integer()
    def max_size do
      Application.get_env(:express, :buffer)[:max_size] ||
      Application.get_env(:express, :module).buffer()[:max_size]
    end

    @spec consumers_count() :: integer()
    def consumers_count do
      Application.get_env(:express, :buffer)[:consumers_count] ||
      Application.get_env(:express, :module).buffer()[:consumers_count]
    end

    @spec consumer_demand_multiplier() :: integer()
    def consumer_demand_multiplier do
      Application.get_env(:express, :buffer)[:consumer_demand_multiplier] ||
      Application.get_env(:express, :module).buffer()[:consumer_demand_multiplier]
    end
  end
end
