defmodule Express.Operations.PoolboyConfigs do
  @moduledoc "Returns poolboy configurations."

  @doc """
  Returns poolboy configuration for the Buffer adders.
  If configuration described in config file - returns it.
  Returns default configuration otherwise.
  """
  @spec buffer_adders() :: %{config: Keyword.t, name: atom()}
  def buffer_adders do
    %{
      config: buffer_adders_pool_config(),
      name: buffer_adders_pool_name()
    }
  end

  @doc """
  Returns poolboy configuration for the FCM workers.
  If configuration described in config file - returns it.
  Returns default configuration otherwise.
  """
  @spec fcm_workers() :: %{config: Keyword.t, name: atom()}
  def fcm_workers do
    %{
      config: fcm_workers_pool_config(),
      name: fcm_workers_pool_name()
    }
  end

  @doc """
  Returns poolboy configuration for the APNS workers.
  If configuration described in config file - returns it.
  Returns default configuration otherwise.
  """
  @spec apns_workers() :: %{config: Keyword.t, name: atom()}
  def apns_workers do
    %{
      config: apns_workers_pool_config(),
      name: apns_workers_pool_name()
    }
  end

  @spec buffer_adders_pool_config() :: Keyword.t
  defp buffer_adders_pool_config do
    Application.get_env(:express, :buffer)[:adders_pool_config] ||
    [
      {:name, {:local, :buffer_adders_pool}},
      {:worker_module, Express.PushRequests.Adder},
      {:size, 5},
      {:max_overflow, 1}
    ]
  end

  @spec buffer_adders_pool_name() :: atom()
  defp buffer_adders_pool_name do
    [{:name, {_, name}} | _] = buffer_adders_pool_config()
    name
  end

  @spec fcm_workers_pool_config() :: Keyword.t
  defp fcm_workers_pool_config do
    Application.get_env(:express, :fcm)[:workers_pool_config] ||
    [
      {:name, {:local, :fcm_workers_pool}},
      {:worker_module, Express.FCM.Worker},
      {:size, System.schedulers_online()}
    ]
  end

  @spec fcm_workers_pool_name() :: atom()
  defp fcm_workers_pool_name do
    [{:name, {_, name}} | _] = fcm_workers_pool_config()
    name
  end

  @spec apns_workers_pool_config() :: Keyword.t
  defp apns_workers_pool_config do
    Application.get_env(:express, :apns)[:workers_pool_config] ||
    [
      {:name, {:local, :apns_workers_pool}},
      {:worker_module, Express.APNS.Worker},
      {:size, System.schedulers_online()}
    ]
  end

  @spec apns_workers_pool_name() :: atom()
  defp apns_workers_pool_name do
    [{:name, {_, name}} | _] = apns_workers_pool_config()
    name
  end
end
