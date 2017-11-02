[![Hex.pm](https://img.shields.io/hexpm/v/express.svg)](https://hex.pm/packages/express) [![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](http://hexdocs.pm/express/) [![Build Status](https://travis-ci.org/madeinussr/express.svg?branch=master)](https://travis-ci.org/madeinussr/express)

# Express

Library for sending push notifications.
Supports Apple APNS and Google FCM services.

At the moment sends pushes to FCM via HTTP and to APNS via HTTP/2 (with either ssl certificate or JWT).

Uses GenServer in order to balance the load. Default buffer (producer) size is 5000.
Default consumer max demand is number_of_available_schedulers * 5 (multiplier can be adjusted).

## Installation

```elixir
# in your mix.exs file

def deps do
  {:express, "~> 1.2.5"}
end

# in your config.exs file (more in configuration section below)

config :express,
       apns: [
         mode: :prod,
         cert_path: "path_to_your_cert.pem",
         key_path: "path_to_your_key.pem"
       ],
       fcm: [
         api_key: "your_key"
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
      content_available: 1,
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

Express can be configured by either config file options or configuration module.

Configuration module is preferable, because it allows you to change some config options dynamically.
Every option from configuration module can be overriden by appropriate option in config file.

### Basic

```elixir
config :express,
       apns: [
         mode: :prod,
         cert_path: "your_cert_path.pem",
         key_path: "your_key_path.pem"
       ],
       fcm: [
         api_key: "your_api_key"
       ]
```

There is an option:

### Buffer

There are all possible options for the buffer:

```elixir
config :express,
       buffer: [
         max_size: 5000,
         consumers_count: 5,
         consumer_demand_multiplier: 5,
         adders_pool_config: [
           {:name, {:local, :buffer_adders_pool}},
           {:worker_module, Express.PushRequests.Adder},
           {:size, 5},
           {:max_overflow, 1}
         ]
       ]
```

### APNS

Possible options for APNS:

_You should provide either (cert_path & key_path) or (cert & key) or (key_id & team_id & auth_key_path)._
_Every "*_path" option has the priority over corresponding option with a file content: `cert_path > cert`, `key_path > key` and `auth_key_path > auth_key`._

*_If you'd like to use cert/key file content, you should use the original content from a file (even with new-line symbols)_*

```elixir
config :express,
       apns: [
         mode: :prod,
         # for requests with jwt
         key_id: "your_key_id",
         team_id: "your_team_id",
         auth_key_path: "your_auth_key_path.p8",

         # for requests with a certificate
         cert_path: "your_cert_path.pem",
         key_path: "your_key_path.pem",

         # workers config (if default doesn't meet you requirements)
         workers_pool_config: [
           {:name, {:local, :apns_workers_pool}},
           {:worker_module, Express.APNS.Worker},
           {:size, 8},
           {:max_overflow, 1}
         ]
       ]
```

### FCM

Possible options for FCM:

```elixir
config :express,
       fcm: [
         api_key: "your_api_key"

         # workers config (if default doesn't meet you requirements)
         workers_pool_config: [
           {:name, {:local, :fcm_workers_pool}},
           {:worker_module, Express.FCM.Worker},
           {:size, 8},
           {:max_overflow, 1}
         ]
       ]
```

### Configuration module

In order to use configuration module, you need:

* create a module that conforms `Express.Configuration` behaviour
* define that module in config file

Let a function return empty list `[]` if you want all default options for a section:

```elixir
  def buffer do
    [] #Express will use default options
  end
```

`Express.Configuration` behaviour is pretty simple, all you need is define functions:

```elixir
@callback buffer() :: Keyword.t
@callback apns() :: Keyword.t
@callback fcm() :: Keyword.t
```

For example (_for more possible options see the sections above_):

```elixir
defmodule YourApp.ExpressConfig.Dev do
  @behaviour Express.Configuration

  def buffer do
    [
      consumers_count: 10
    ]
  end

  def apns do
    [
      mode: :dev,
      key_id: "your_key_id",
      team_id: "your_team_id",
      auth_key: "your_auth_key"
    ]
  end

  def fcm do
    [
      api_key: "your_api_key"
    ]
  end
end
```

Then in `config/dev.exs`:

```elixir
config :express, module: YourApp.ExpressConfig.Dev
```

As said earlier, you can even override your configuration module options later in config file:

```elixir
config :express,
       module: YourApp.ExpressConfig.Dev,
       buffer: [
         consumers_count: 5
       ]
```

_configuration in config files has the highest priority_

*Do not forget to add configuration module to .gitignore if it contains secret data*

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
  thread_id: String.t,
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

## Supervision tree

```elixir
                                     Application
                                          |
                                    Supervisor 
                                          |
          -----------------------------------------------------------------------
          |                    |                        |                       |
   APNS.Supervisor      FCM.Supervisor       PushRequests.Supervisor      TasksSupervisor
          |                    |                                 |              |
          |         -------------------------                    |   ------------------------
          |         |                       |                    |   |          |           |
          |  FCM.DelayedPushes      :fcm_workers_pool            |  Task       Task        Task
          |                                 |                    |
          |                     ------------------------         |
          |                     |           |          |         |
          |                 FCM.Worker  FCM.Worker  FCM.Worker   |
          |                                                      |
          |                               ----------------------------------------
          |                               |               |                      |
          |                     PushRequests.Buffer   :buffer_adders_pool   PushRequests.ConsumersSupervisor
          |                                               |                      |
          |                                        -------------         ----------------
          |                                        |           |         |              |
          |                                        |           |PushRequests.Consumer  PushRequests.Consumer
          |                                        |           |
          |                               PushRequests.Adder  PushRequests.Adder
          |
      ---------------------------------------------
      |                      |                    |
APNS.JWTHolder      APNS.DelayedPushes    :apns_workers_pool
                                                  |
                                         --------------------------------------
                                         |                |                   |
                                    APNS.Worker      APNS.Worker         APNS.Worker
                                         |                |                   |
                                  APNS.Connection   APNS.Connection    APNS.Connection
```

## LICENSE

    Copyright © 2017 Andrey Chernykh ( andrei.chernykh@gmail.com )

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.
