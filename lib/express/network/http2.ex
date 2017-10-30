defmodule Express.Network.HTTP2 do
  @moduledoc """
  Module with functions for establishing and working with HTTP2-connection.
  """

  alias Express.Configuration
  alias Express.Network.HTTP2.{Connection, Client}
  alias Express.APNS

  @doc """
  Establishes a connection for `provider` with either `ssl_config` or `jwt` and `client` which maintains the connection.
  Returns the connection.
  """
  @spec connect(Client.t, atom(), APNS.SSLConfig.t | String.t) :: {:ok, Connection.t} |
                                                                  {:error, any()}
  def connect(client, provider, ssl_config) when is_map(ssl_config) do
    case client.open_socket(provider, ssl_config, 0) do
      {:ok, socket} ->
        params = %{
          client: client,
          provider: provider,
          socket: socket,
          ssl_config: ssl_config
        }

        {:ok, Connection.new(params)}
      error ->
        error
    end
  end

  def connect(client, provider) do
    mode = Configuration.APNS.mode()

    case client.open_socket(provider, mode, 0) do
      {:ok, socket} ->
        params = %{
          client: client,
          provider: provider,
          socket: socket
        }

        {:ok, Connection.new(params)}
      error ->
        error
    end
  end

  @doc "Sends a request via a connection with `headers` and `payload`"
  @spec send_request(Connection.t, list(), String.t) :: {:ok, pid()} | any()
  def send_request(%{client: client, socket: socket} = _connection, headers, payload) do
    client.send_request(socket, headers, payload)
  end

  @doc "Gets a response from connection stream"
  @spec get_response(pid(), pid()) :: {:ok, {String.t, String.t}} | any()
  def get_response(%{client: client, socket: socket} = _connection, stream) do
    client.get_response(socket, stream)
  end
end
