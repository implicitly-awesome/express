defmodule Express.APNS.SSLConfig do
  @moduledoc """
  Provides APNS SSL configuration constructor.
  """

  alias Express.Network.HTTP2.SSLConfig

  @doc "Creates SSL configuration with provided `opts`"
  @spec new(Keyword.t) :: SSLConfig.t
  def new(opts \\ []) do
    mode =
      opts[:mode] ||
      config_mode()
    cert =
      opts[:cert] ||
      cert(config_cert_path()) ||
      decode_content(config_cert(), :cert)
    key =
      opts[:key] ||
      key(config_key_path()) ||
      decode_content(config_key(), :key)

    %SSLConfig{
      mode: mode,
      cert: cert,
      key:  key
    }
  end

  @doc "Returns apns mode from configuration"
  @spec config_mode() :: atom() | String.t | nil
  def config_mode, do: Application.get_env(:express, :apns)[:mode]

  @doc "Returns SSL certificate path from configuration"
  @spec config_cert_path() :: String.t | nil
  def config_cert_path, do: Application.get_env(:express, :apns)[:cert_path]

  @doc "Returns SSL key path from configuration"
  @spec config_key_path() :: String.t | nil
  def config_key_path, do: Application.get_env(:express, :apns)[:key_path]

  @doc "Returns SSL certificate from configuration"
  @spec config_cert() :: String.t | nil
  def config_cert, do: Application.get_env(:express, :apns)[:cert]

  @doc "Returns SSL key from configuration"
  @spec config_key() :: String.t | nil
  def config_key, do: Application.get_env(:express, :apns)[:key]

  @doc "Returns SSL certificate by file path"
  @spec cert(String.t) :: binary()
  def cert(file_path) when is_binary(file_path) do
    file_path |> read_file |> decode_content(:cert)
  end
  def cert(_), do: nil

  @doc "Returns SSL key by file path"
  @spec key(String.t) :: binary()
  def key(file_path) when is_binary(file_path) do
    file_path |> read_file |> decode_content(:key)
  end
  def key(_), do: nil

  @doc "Returns a file content by file path"
  @spec read_file(String.t) :: String.t | nil
  def read_file(file_path) when is_binary(file_path) do
    with true <- :filelib.is_file(file_path),
         full_file_path <- Path.expand(file_path),
         {:ok, content} <- File.read(full_file_path) do
           content
         else
           _ -> nil
         end
  end

  @doc "Returns either SSL certificate or SSL key from a file content"
  @spec decode_content(String.t, :cert | :key) :: binary() | nil
  def decode_content(file_content, type) when is_binary(file_content) and is_atom(type) do
    file_content = file_content |> String.replace("\\n", "\n")
    try do
      case type do
        :cert -> fetch_cert(:public_key.pem_decode(file_content))
        :key -> fetch_key(:public_key.pem_decode(file_content))
        _ -> nil
      end
    rescue
      _ -> nil
    end
  end
  def decode_content(_file_content, _type), do: nil

  @doc "Returns SSL certificate from pem"
  @spec fetch_cert(list()) :: binary() | nil
  def fetch_cert([]), do: nil
  def fetch_cert([{:Certificate, cert, _} | _tail]), do: cert
  def fetch_cert([_head | tail]), do: fetch_cert(tail)
  def fetch_cert(_), do: nil

  @doc "Returns SSL key from pem"
  @spec fetch_key(list()) :: binary() | nil
  def fetch_key([]), do: nil
  def fetch_key([{:RSAPrivateKey, key, _} | _tail]), do: {:RSAPrivateKey, key}
  def fetch_key([_head | tail]), do: fetch_key(tail)
  def fetch_key(_), do: nil
end
