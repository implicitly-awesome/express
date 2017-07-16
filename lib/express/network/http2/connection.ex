defmodule Express.Network.HTTP2.Connection do
  @moduledoc """
  Specifies HTTP2 connection's structure, where:
    * `client` - client that serves a connection
    * `provider` - push provider (:apns or :fcm)
    * `socket` - opened socket
    * `ssl_config` - SSL configuration
  """

  alias Express.Network.HTTP2

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{client: HTTP2.Client.t,
                         provider: atom(),
                         socket: pid(),
                         ssl_config: HTTP2.SSLConfig.t}

  defstruct ~w(client provider socket ssl_config)a
end
