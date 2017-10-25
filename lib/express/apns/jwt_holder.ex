defmodule Express.APNS.JWTHolder do
  use GenServer

  import Joken

  alias JOSE.JWK

  @algorithm "ES256"
  @ttl 50 * 60

  defmodule State do
    @type t :: %__MODULE__{jwt: String.t, iat: integer()}

    defstruct ~w(jwt iat)a
  end

  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok) do
    now = Timex.now()
    jwt = new(now)

    {:ok, %State{jwt: jwt, iat: now}}
  end

  def get_jwt, do: GenServer.call(__MODULE__, :get_jwt)

  def handle_call(:get_jwt, _from, state) do
    state =
      if expired?(state.iat) do
        now = Timex.now()
        jwt = new(now)

        %State{jwt: jwt, iat: now}
      else
        state
      end

    {:reply, state.jwt, state}
  end

  defp new(iat) do
    %{
      "iss" => Application.get_env(:express, :apns)[:team_id],
      "iat" => Timex.to_unix(iat)
    }
    |> token()
    |> with_header_arg("alg", @algorithm)
    |> with_header_arg("kid", Application.get_env(:express, :apns)[:key_id])
    |> with_signer(es256(auth_key()))
    |> sign()
    |> get_compact()
  end

  def auth_key do
    :express
    |> Application.get_env(:apns)
    |> Keyword.get(:auth_key_path)
    |> JWK.from_pem_file
  end

  def expired?(iat) do
    Timex.diff(Timex.now(), iat, :seconds) > @ttl
  end
end
