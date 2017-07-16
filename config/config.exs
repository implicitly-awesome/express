use Mix.Config

config :express,
       apns: [
         poolboy: [
           {:name, {:local, :apns_clients_pool}},
           {:worker_module, Express.APNS.Client},
           {:size, 10},
           {:max_overflow, 3}
         ]
       ],
       fcm: [
         poolboy: [
           {:name, {:local, :fcm_clients_pool}},
           {:worker_module, Express.FCM.Client},
           {:size, 10},
           {:max_overflow, 3}
         ]         
       ]

import_config "#{Mix.env}.exs"
