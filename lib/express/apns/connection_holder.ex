defmodule Express.APNS.ConnectionHolder do
  @moduledoc """
  Establishes and holds a connection to APNS.
  """

  use GenServer
  alias Express.Operations.LogMessage

  alias Express.Operations.EstablishHTTP2Connection
  alias Express.APNS.{SSLConfig, JWT}
  alias Express.Network.HTTP2.{ChatterboxClient, Connection}

  defmodule State do
    @moduledoc """
    Defines APNS connection holder state structure.
    """

    @type t :: %__MODULE__{connection: HTTP2.Connection.t}

    defstruct ~w(connection)a

    @spec new(Keyword.t) :: __MODULE__.t
    def new(args) do
      %__MODULE__{connection: Keyword.get(args, :connection)}
    end
  end

  @spec start_link() :: GenServer.on_start
  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok) do
    if %Connection{} = connection = make_connection() do
      {:ok, %State{connection: connection}}
    else
      {:stop, :connection_not_established}
    end
  end

  def connection, do: GenServer.call(__MODULE__, :get_connection)

  def handle_call(:get_connection, _from, %{connection: connection} = state) do
    if connection.ssl_config do
      {:reply, connection, state}
    else
      if connection.jwt do
        connection = connection_refreshed_jwt(connection)
        {:reply, connection, Map.put(state, :connection, connection)}
      end
    end
  end

  @spec need_ssl_config?() :: boolean()
  defp need_ssl_config? do
    Application.get_env(:express, :apns)[:cert_path] &&
      Application.get_env(:express, :apns)[:key_path]
  end

  @spec need_jwt?() :: boolean()
  defp need_jwt? do
    Application.get_env(:express, :apns)[:key_id] &&
      Application.get_env(:express, :apns)[:team_id] &&
      Application.get_env(:express, :apns)[:auth_key_path]
  end

  @spec make_connection :: Connection.t | nil
  defp make_connection do
    params =
      if need_ssl_config?() do
        [
          http2_client: ChatterboxClient,
          ssl_config: SSLConfig.new()
        ]
      else
        if need_jwt?() do
          [
            http2_client: ChatterboxClient,
            jwt: JWT.new()
          ]
        end
      end

    case EstablishHTTP2Connection.run(params) do
      {:ok, connection} -> connection
      _ -> nil
    end
  end

  defp connection_refreshed_jwt(connection) do
    if JWT.expired?(connection.jwt) do
      Map.put(connection, :jwt, JWT.new())
    else
      connection
    end
  end
end
