defmodule Express.APNS.JWT do
  @moduledoc """
  Generates APNS JWT.
  """

  import Joken

  alias JOSE.JWK

  @algorithm "ES256"
  @ttl 5

  def new do
    now = Timex.to_unix(Timex.now())

    %{
      "iss" => Application.get_env(:express, :apns)[:team_id],
      "iat" => now
    }
    |> token()
    |> with_header_arg("alg", @algorithm)
    |> with_header_arg("kid", Application.get_env(:express, :apns)[:key_id])
    |> with_signer(es256(auth_key()))
    |> sign()
    |> get_compact()
  end

  def expired?(jwt) when is_binary(jwt) do
    iat =
      jwt
      |> token()
      |> with_signer(es256(auth_key()))
      |> verify()
      |> Map.get(:claims)
      |> Map.get("iat")
      |> Timex.from_unix()

    Timex.diff(Timex.now(), iat, :seconds) > @ttl
  end

  defp auth_key do
    :express
    |> Application.get_env(:apns)
    |> Keyword.get(:auth_key_path)
    |> JWK.from_pem_file
  end
end
