use Mix.Config

config :express,
       apns: [
         mode: :prod,
         key_id: System.get_env("EXPRESS_APNS_KEY_ID"),
         team_id: System.get_env("EXPRESS_APNS_TEAM_ID"),
         auth_key_path: System.get_env("EXPRESS_APNS_AUTH_KEY_PATH")
       ],
       fcm: [
         api_key: System.get_env("EXPRESS_FCM_API_KEY")
       ],
       buffer: [
         consumers_count: 10
       ]
