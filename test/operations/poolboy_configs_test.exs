defmodule Operations.PoolboyConfigsTest do
  @moduledoc false

  alias Express.Operations.PoolboyConfigs

  use ExUnit.Case, async: true

  describe "default values" do
    test "fcm_workers/0" do
      default_config =
        %{
          config: [
            {:name, {:local, :fcm_workers_pool}},
            {:worker_module, Express.FCM.Worker},
            {:size, System.schedulers_online()}
          ],
          name: :fcm_workers_pool
        }

      assert default_config == PoolboyConfigs.fcm_workers()
    end

    test "apns_workers/0" do
      default_config =
        %{
          config: [
            {:name, {:local, :apns_workers_pool}},
            {:worker_module, Express.APNS.Worker},
            {:size, System.schedulers_online()}
          ],
          name: :apns_workers_pool
        }

      assert default_config == PoolboyConfigs.apns_workers()
    end
  end

  describe "values from config file" do
    test "buffer_adders/0" do
      from_config = Application.get_env(:express, :buffer)[:adders_pool_config]

      assert from_config == PoolboyConfigs.buffer_adders().config
    end
  end
end
