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

  @spec config_mode() :: atom() | String.t | nil
  defp config_mode, do: Application.get_env(:express, :apns)[:mode]

  @spec config_cert_path() :: String.t | nil
  defp config_cert_path, do: Application.get_env(:express, :apns)[:cert_path]

  @spec config_key_path() :: String.t | nil
  defp config_key_path, do: Application.get_env(:express, :apns)[:key_path]

  @spec config_cert() :: String.t | nil
  defp config_cert, do: Application.get_env(:express, :apns)[:cert]

  @spec config_key() :: String.t | nil
  defp config_key, do: Application.get_env(:express, :apns)[:key]

  @spec cert(String.t) :: binary()
  defp cert(file_path) when is_binary(file_path) do
    file_path |> read_file |> decode_content(:cert)
  end
  defp cert(_), do: nil

  @spec key(String.t) :: binary()
  defp key(file_path) when is_binary(file_path) do
    file_path |> read_file |> decode_content(:key)
  end
  defp key(_), do: nil

  @spec read_file(String.t) :: String.t | nil
  defp read_file(file_path) when is_binary(file_path) do
    with true <- :filelib.is_file(file_path),
         full_file_path <- Path.expand(file_path),
         {:ok, content} <- File.read(full_file_path) do
           content
         else
           _ -> nil
         end
  end

  @spec decode_content(String.t, :cert | :key) :: binary() | nil
  defp decode_content(file_content, type) when is_binary(file_content) and is_atom(type) do
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
  defp decode_content(_file_content, _type), do: nil

  @spec fetch_cert(list()) :: binary() | nil
  defp fetch_cert([]), do: nil
  defp fetch_cert([{:Certificate, cert, _} | _tail]), do: cert
  defp fetch_cert([_head | tail]), do: fetch_cert(tail)
  defp fetch_cert(_), do: nil

  @spec fetch_key(list()) :: binary() | nil
  defp fetch_key([]), do: nil
  defp fetch_key([{:RSAPrivateKey, key, _} | _tail]), do: {:RSAPrivateKey, key}
  defp fetch_key([_head | tail]), do: fetch_key(tail)
  defp fetch_key(_), do: nil
end
