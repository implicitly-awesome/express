use Mix.Config

# do not write into logs during tests
config :logger,
       backends: []

config :express,
       module: Express.Configuration.Test,
       buffer: [
         max_size: 1000
       ],
       environment: :test
