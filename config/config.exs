use Mix.Config

config :express,
       apns: [
         poolboy: [
           {:name, {:local, :apns_supervisors_pool}},
           {:worker_module, Express.APNS.Supervisor},
           {:size, 10},
           {:max_overflow, 3}
         ]
       ],
       fcm: [
         poolboy: [
           {:name, {:local, :fcm_supervisors_pool}},
           {:worker_module, Express.FCM.Supervisor},
           {:size, 10},
           {:max_overflow, 3}
         ]         
       ]

import_config "#{Mix.env}.exs"
