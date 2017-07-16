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
       ]
