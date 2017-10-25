defmodule Express.Operations.PoolboyConfigs do
  def buffer_adders do
    %{
      config: buffer_adders_pool_config(),
      name: buffer_adders_pool_name()
    }
  end

  def fcm_workers do
    %{
      config: fcm_workers_pool_config(),
      name: fcm_workers_pool_name()
    }
  end

  def apns_workers do
    %{
      config: apns_workers_pool_config(),
      name: apns_workers_pool_name()
    }
  end

  defp buffer_adders_pool_config do
    Application.get_env(:express, :buffer)[:adders_pool_config] ||
    [
      {:name, {:local, :buffer_adders_pool}},
      {:worker_module, Express.PushRequests.Adder},
      {:size, 5},
      {:max_overflow, 1}
    ]
  end

  defp buffer_adders_pool_name do
    [{:name, {_, name}} | _] = buffer_adders_pool_config()
    name
  end

  defp fcm_workers_pool_config do
    Application.get_env(:express, :fcm)[:workers_pool_config] ||
    [
      {:name, {:local, :fcm_workers_pool}},
      {:worker_module, Express.FCM.Worker},
      {:size, System.schedulers_online()}
    ]
  end

  defp fcm_workers_pool_name do
    [{:name, {_, name}} | _] = fcm_workers_pool_config()
    name
  end

  defp apns_workers_pool_config do
    Application.get_env(:express, :apns)[:workers_pool_config] ||
    [
      {:name, {:local, :apns_workers_pool}},
      {:worker_module, Express.APNS.Worker},
      {:size, System.schedulers_online()}
    ]
  end

  defp apns_workers_pool_name do
    [{:name, {_, name}} | _] = apns_workers_pool_config()
    name
  end
end
