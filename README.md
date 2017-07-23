# Express [![Build Status](https://img.shields.io/travis/madeinussr/express.svg?style=flat)](https://travis-ci.org/madeinussr/express)

Library for sending push notifications.
Supports Apple APNS and Google FCM services.

Express - reviewed and remastered [Dufa](https://github.com/madeinussr/dufa) library with some core improvements:

* utilizes poolboy (default pool size = 5, max_overflow = 1)
* supervision tree was reviewed (worker per push, connection per supervisor (APNS))
* DI in supervision tree allows to develop, test and maintain code with ease

Moreover, Express was battle tested on production.

## Installation

```elixir
# in your mix.exs file

def deps do
  {:express, "~> 1.0"}
end

# in your config.exs file (more in configuration section below)

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
```

## Quick examples

### APNS

```elixir
alias Express.APNS

push_message =
  %APNS.PushMessage{
    token: "your_device_token",
    topic: "your_app_topic",
    acme: %{},
    aps: %APNS.PushMessage.Aps{
      badge: 1,
      content_available: true,
      alert: %APNS.PushMessage.Alert{
        title: "Hello",
        body: "World"
      }
    }
  }

opts = [delay: 5] # in seconds

callback_fun =
  fn(push_message, response) ->
    IO.inspect("==Push message==")
    IO.inspect(push_message)
    IO.inspect("==APNS response==")
    IO.inspect(response)
  end

APNS.push(push_message, opts, callback_fun)
```

### FCM

```elixir
alias Express.FCM

push_message =
  %FCM.PushMessage{
    to: "your_device_registration_id",
    priority: "high",
    content_available: true,
    data: %{},
    notification: %FCM.PushMessage.Notification{
      title: "Hello",
      body: "World"
    }
  }

opts = [delay: 5] # in seconds

callback_fun =
  fn(push_message, response) ->
    IO.inspect("==Push message==")
    IO.inspect(push_message)
    IO.inspect("==FCM response==")
    IO.inspect(response)
  end

FCM.push(push_message, opts, callback_fun)
```

## Configuration

As described earlier, the simpliest configuration for Express might look like:

```elixir
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
```

However there are some options:

* for APNS you can provide also `cert` and `key` options (values/content of your certificate and key files respectively)
  the priority of the options is: `cert_path > cert` and `key_path > key`

* you can edit poolboy configuration with `poolboy` option for both APNS and FCM:

```elixir
config :express,
       apns: [
         mode: :prod,
         cert: System.get_env("EXPRESS_APNS_CERT"),
         key: System.get_env("EXPRESS_APNS_KEY")
       ],
       fcm: [
         api_key: System.get_env("EXPRESS_FCM_API_KEY"),
         collapse_key: System.get_env("EXPRESS_FCM_COLLAPSE_KEY")
         poolboy: [
           {:name, {:local, :fcm_supervisors_pool}},
           {:worker_module, Express.FCM.Supervisor},
           {:size, 10}, # default is 5
           {:max_overflow, 3} # default is 1
         ]
       ]
```

## Push message structure

You should construct `%Express.APNS.PushMessage{}` and `%Express.FCM.PushMessage{}`
structures and pass them to `Express.APNS.push/3` and `Express.FCM.push/3` respectively
in order to send a push message.

Express's `Express.APNS.PushMessage` as well as `Express.FCM.PushMessage` conforms official
Apple & Google push message structures, so there should not be any confusion with it.

Here are their structures:

### APNS

```elixir
%Express.APNS.PushMessage{
  token: String.t,
  topic: String.t,
  aps: Express.APNS.PushMessage.Aps.t,
  apple_watch: map(),
  acme: map()
}

%Express.APNS.PushMessage.Aps{
  content_available: pos_integer(),
  mutable_content: pos_integer(),
  badge: pos_integer(),
  sound: String.t,
  category: String.t,
  alert: Express.APNS.PushMessage.Alert.t | String.t
}

%Express.APNS.PushMessage.Alert{
  title: String.t,
  body: String.t
}
```

### FCM

```elixir
%Express.FCM.PushMessage{
  to: String.t,
  registration_ids: [String.t],
  priority: String.t,
  content_available: boolean(),
  collapse_key: String.t,
  data: map(),
  notification: PushMessage.Notification.t
}

%Express.FCM.PushMessage.Notification{
  title: String.t,
  body: String.t,
  icon: String.t,
  sound: String.t,
  click_action: String.t,
  badge: pos_integer(),
  category: String.t
}
```

## Send a push message

In order to send a push message you should to construct a valid message structure,
define a callback function, which will be invoked on provider's response (APNS or FCM)
and pass them along with options to either `Express.FCM.push/3` or `Express.APNS.push/3`
function (see quick examples above).

Nothing to add here, but:

* a callback function has to take two arguments:
  * a push message (which push message structure you tried to send)
  * a push result (response received from a provider and handled by Express)

```elixir
# push result type
@type push_result :: {:ok, %{status: pos_integer(), body: any()}} |
                     {:error, %{status: pos_integer(), body: any()}}
```

* at this moment the single option you can pass with `opts` argument - `delay`
  * it defines a delay in seconds for a push worker (a worker will push a message after that delay)

## Bonus: supervision tree

```elixir
# FCM

                   Express.Supervisor
                           |
          ---------------------------------
          |                               |
APNS Supervisors pool            FCM Supervisors pool
                                          |
                         -----------------------------------
                         |            |                    |
                         |    Workers Supervisor   Workers Supervisor
                         |
                 Workers Supervisor
                         |
                 ------------------
                 |       |        |
              Worker   Worker   Worker


# APNS

               Express.Supervisor
                        |
          -----------------------------
          |                           |
FCM Supervisors pool        APNS Supervisors pool
                                      |
                         ------------------------------------
                         |            |                     |
                         |   Workers Supervisor    Workers Supervisor
                         |
                Workers Supervisor
                         |
                ------------------
                |                |
                |    HTTP2 connection (a supervisor owns a connection)
                |
        ------------------
        |       |        |
    Worker   Worker   Worker (spawned with a connection passed as an argument)

```

## LICENSE

    Copyright © 2017 Andrey Chernykh ( andrei.chernykh@gmail.com )

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.
