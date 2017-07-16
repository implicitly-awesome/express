use Mix.Config

config :express,
       apns: [
         mode: :prod,
         cert_path: System.get_env("EXPRESS_APNS_CERT_PATH"),
         key_path: System.get_env("EXPRESS_APNS_KEY_PATH")
       ],
       fcm: [
         api_key: System.get_env("EXPRESS_FCM_API_KEY"),
         collapse_key: System.get_env("EXPRESS_FCM_COLLAPSE_KEY")
       ]
