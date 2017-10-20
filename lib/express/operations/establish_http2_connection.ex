defmodule Express.Operations.EstablishHTTP2Connection do
  @moduledoc """
  Establishes HTTP2 connection and returns it.
  
  [Exop](https://github.com/madeinussr/exop) library operation.

  Takes parameters:
  * `http2_client` (a module that conforms `Express.Network.HTTP2.Client` behaviour)
  * `ssl_config` (a structure that conforms `Express.Network.HTTP2.SSLConfig` behaviour)
  """

  use Exop.Operation

  alias Express.Network.HTTP2
  alias Express.Network.HTTP2.SSLConfig
  alias Express.Operations.LogMessage

  parameter :http2_client, required: true
  parameter :ssl_config, struct: %SSLConfig{}
  parameter :jwt, type: :string

  def process(contract) when is_list(contract) do
    contract |> Enum.into(%{}) |> process()
  end
  def process(%{http2_client: http2_client, ssl_config: ssl_config})
      when is_map(ssl_config) do
    case HTTP2.connect(http2_client, :apns, ssl_config) do
      {:ok, connection} ->
        connection
      {:error, :open_socket, :timeout} ->
        error_message = """
        [APNS supervisor] Could not establish a connection with APNS.
        Is certificate valid and signed for :#{inspect(ssl_config[:mode])} mode? 
        """
        LogMessage.run!(message: error_message)

        {:error, :timeout}
      {:error, :ssl_config, reason} ->
        error_message = """
        [APNS supervisor] Could not establish a connection with APNS.
        Invalid SSL configuration: #{inspect(reason)}
        """
        LogMessage.run!(message: error_message)

        {:error, :invalid_ssl_config}
      _ ->
        error_message = """
        [APNS supervisor] Could not establish a connection with APNS.
        Unhandled error occured.
        """
        LogMessage.run!(message: error_message)

        {:error, :unhandled}
    end
  end
  def process(%{http2_client: http2_client, jwt: jwt}) when is_binary(jwt) do
    case HTTP2.connect(http2_client, :apns, jwt) do
      {:ok, connection} ->
        connection
      {:error, :open_socket, :timeout} ->
        error_message = """
        [APNS supervisor] Could not establish a connection with APNS.
        Timeout.
        """
        LogMessage.run!(message: error_message)

        {:error, :timeout}
      _ ->
        error_message = """
        [APNS supervisor] Could not establish a connection with APNS.
        Unhandled error occured.
        """
        LogMessage.run!(message: error_message)

        {:error, :unhandled}
    end
  end
  def process(_) do
    error_message = """
    [APNS supervisor] Could not establish a connection with APNS.
    Need to provide either a ssl config or jwt.
    """
    LogMessage.run!(message: error_message)

    {:error, :invalid_args}
  end
end
