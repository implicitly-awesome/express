defmodule Express.Network.HTTP2.ChatterboxClient do
  @behaviour Express.Network.HTTP2.Client
  @moduledoc """
  HTTP2-client which conforms Express.Network.HTTP2.Client behaviour with chatterbox library.
  """

  def uri(:apns, :prod), do: to_char_list("api.push.apple.com")
  def uri(:apns, :dev), do: to_char_list("api.development.push.apple.com")

  def open_socket(_, _, 3), do: {:error, :open_socket, :timeout}
  def open_socket(_provider, %{cert: nil}, _tries), do: {:error, :ssl_config, :certificate_missed}
  def open_socket(_provider, %{key: nil}, _tries), do: {:error, :ssl_config, :rsa_key_missed}
  def open_socket(_provider, %{mode: nil}, _tries), do: {:error, :ssl_config, :mode_missed}
  def open_socket(provider, %{mode: mode, cert: cert, key: key} = ssl_config, tries) do
    config = socket_config({:cert, cert}, {:key, key})
    result = :h2_client.start_link(:https, uri(provider, mode), config)
    case result do
      {:ok, socket} -> {:ok, socket}
      _ -> open_socket(provider, ssl_config, (tries + 1))
    end
  end
  def open_socket(provider, mode, tries) when is_atom(mode) do
    result = :h2_client.start_link(:https,
                                   uri(provider, mode),
                                   default_socket_config())
    case result do
      {:ok, socket} -> {:ok, socket}
      _ -> open_socket(provider, mode, (tries + 1))
    end
  end
  def open_socket(_, _, _), do: {:error, :ssl_config, :invalid_ssl_config}

  def send_request(socket, headers, payload) do
    :h2_client.send_request(socket, headers, payload)
  end

  def sync_request(socket, headers, payload) do
    :h2_client.sync_request(socket, headers, payload)
  end

  def ping(socket) do
    :h2_client.send_ping(socket)
  end

  def get_response(socket, stream) do
    :h2_client.get_response(socket, stream)
  end

  @spec default_socket_config() :: list()
  defp default_socket_config do
    [
      {:password, ''},
      {:packet, 0},
      {:reuseaddr, true},
      {:active, true},
      :binary
    ]
  end

  @spec socket_config(binary(), binary()) :: list()
  defp socket_config(cert, key) do
    default_socket_config() ++ [cert, key]
  end
end
