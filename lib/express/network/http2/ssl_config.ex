defmodule Express.Network.HTTP2.SSLConfig do
  @moduledoc """
  Specifies a behaviour and SSL configuration structure, where:
    * `mode` - either :dev or :prod
    * `cert` - SSL certificate
    * `key` - RSA key
  """

  defstruct ~w(mode cert key)a

  @type t :: %__MODULE__{mode: atom() | String.t,
                         cert: binary(),
                         key: binary()}

  @doc "SSL-configuration constructor (for provided arguments)."
  @callback new(Keyword.t) :: __MODULE__.t
end