defmodule Express.Network.HTTP2.Connection do
  @moduledoc """
  Specifies HTTP2 connection's structure, where:
    * `client` - client that serves a connection
    * `provider` - push provider (:apns or :fcm)
    * `socket` - opened socket
    * `ssl_config` - SSL configuration (optional)
    * `jwt` - JWT (optional)
  """

  alias Express.Network.HTTP2

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{client: HTTP2.Client.t,
                         provider: atom(),
                         socket: pid(),
                         ssl_config: HTTP2.SSLConfig.t,
                         jwt: String.t}

  defstruct ~w(client provider socket ssl_config jwt)a

  def new(args) do
    if args[:ssl_config] do
      new_with_ssl_config(args)
    else
      if args[:jwt] do
        new_with_jwt(args)
      end
    end
  end

  defp new_common(args) do
    %__MODULE__{
      client: args[:client],
      provider: args[:provider],
      socket: args[:socket]
    }
  end

  defp new_with_ssl_config(args) do
    args |> new_common() |> Map.put(:ssl_config, args[:ssl_config])
  end

  defp new_with_jwt(args) do
    args |> new_common() |> Map.put(:jwt, args[:jwt])
  end
end
