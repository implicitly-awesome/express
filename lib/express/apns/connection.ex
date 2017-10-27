defmodule Express.APNS.Connection do
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
    (Application.get_env(:express, :apns)[:cert_path] ||
     Application.get_env(:express, :apns)[:cert]) &&
    (Application.get_env(:express, :apns)[:key_path] ||
     Application.get_env(:express, :apns)[:key])
  end
end
