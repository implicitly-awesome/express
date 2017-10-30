defmodule Express.APNS.Connection do
  @moduledoc """
  Establishes a connection to APNS with proper configuration.
  """

  alias Express.Configuration
  alias Express.Operations.EstablishHTTP2Connection
  alias Express.APNS.SSLConfig
  alias Express.Network.HTTP2.ChatterboxClient

  def new do
    params =
      if need_ssl_config?() do
        [http2_client: ChatterboxClient, ssl_config: SSLConfig.new()]
      else
        [http2_client: ChatterboxClient]
      end

    case EstablishHTTP2Connection.run(params) do
      {:ok, connection} -> connection
      _ -> nil
    end
  end

  def need_ssl_config? do
    (Configuration.APNS.cert_path() || Configuration.APNS.cert()) &&
    (Configuration.APNS.key_path() || Configuration.APNS.key())
  end
end
