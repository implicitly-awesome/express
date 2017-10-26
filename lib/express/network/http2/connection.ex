defmodule Express.Network.HTTP2.Connection do
  @moduledoc "Defines a structure for general HTTP2 connection."

  alias Express.Network.HTTP2

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{client: HTTP2.Client.t,
                         provider: atom(),
                         socket: pid(),
                         ssl_config: HTTP2.SSLConfig.t}

  defstruct ~w(client provider socket ssl_config)a

  @doc "Structure constructor."
  @spec new(Keyword.t) :: t
  def new(args) do
    if args[:ssl_config] do
      new_with_ssl_config(args)
    else
      new_common(args)
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
end
