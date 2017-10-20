use Mix.Config

config :express,
       apns: [
         mode: :prod,
         key_id: "2MV43XVTEE",
         team_id: "568PSBRERR",
         auth_key_path: "/Users/andreichernykh/Documents/Projects/erlang/elixir/auth_key_old.p8"
        #  key_id: System.get_env("EXPRESS_APNS_KEY_ID"),
        #  team_id: System.get_env("EXPRESS_APNS_TEAM_ID"),
        #  auth_key_path: System.get_env("EXPRESS_APNS_AUTH_KEY_PATH")
        #  cert_path: System.get_env("EXPRESS_APNS_CERT_PATH"),
        #  key_path: System.get_env("EXPRESS_APNS_KEY_PATH")
       ],
       fcm: [
         api_key: System.get_env("EXPRESS_FCM_API_KEY"),
         collapse_key: System.get_env("EXPRESS_FCM_COLLAPSE_KEY")
       ]
