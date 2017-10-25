use Mix.Config

# do not write into logs during tests
config :logger,
       backends: []

config :express,
       apns: [
         mode: :dev,
         cert_path: Path.expand("test/fixtures/test_apns_cert.pem"),
         key_path: Path.expand("test/fixtures/test_apns_key.pem")
       ],
       fcm: [
         api_key: "your_api_key",
         collapse_key: "your_collapse_key"
       ],
       buffer: [
        adders_pool_config: [
          {:name, {:local, :buffer_adders_pool}},
          {:worker_module, Express.PushRequests.Adder},
          {:size, 10},
          {:max_overflow, 2}
        ],
        consumers_count: 10,
        max_size: 10_000
       ]
