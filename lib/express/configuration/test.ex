defmodule Express.Configuration.Test do
  @moduledoc """
  Configuration for :test environment.
  Conforms Express.Configuration behaviour
  """

  @behaviour Express.Configuration

  def buffer do
    [
      adders_pool_config: [
        {:name, {:local, :buffer_adders_pool}},
        {:worker_module, Express.PushRequests.Adder},
        {:size, 10},
        {:max_overflow, 2}
      ],
      consumers_count: 10,
      max_size: 10_000
    ]
  end

  def apns do
    [
      mode: :dev,
      cert_path: Path.expand("test/fixtures/test_apns_cert.pem"),
      key_path: Path.expand("test/fixtures/test_apns_key.pem"),
      key_id: "key_id",
      team_id: "team_id",
      auth_key_path: Path.expand("test/fixtures/test_auth_key.p8")
    ]
  end

  def fcm do
    [
      api_key: "your_api_key",
      collapse_key: "your_collapse_key"
    ]
  end
end
