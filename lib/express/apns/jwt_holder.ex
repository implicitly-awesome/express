defmodule Express.APNS.JWTHolder do
  use GenServer

  import Joken

  alias JOSE.JWK
  alias Express.Configuration

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
      "iss" => Configuration.APNS.team_id(),
      "iat" => Timex.to_unix(iat)
    }
    |> token()
    |> with_header_arg("alg", @algorithm)
    |> with_header_arg("kid", Configuration.APNS.key_id())
    |> with_signer(es256(apns_auth_key()))
    |> sign()
    |> get_compact()
  end

  def apns_auth_key do
    if path = auth_key_path() do
      JWK.from_pem_file(path)
    else
      if key = auth_key() do
        key
        |> String.replace("\\n", "\n")
        |> JWK.from_pem()
      end
    end
  end

  def expired?(iat), do: Timex.diff(Timex.now(), iat, :seconds) > @ttl

  defp auth_key_path, do: Configuration.APNS.auth_key_path()

  defp auth_key, do: Configuration.APNS.auth_key()
end
