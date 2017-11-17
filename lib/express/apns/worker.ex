defmodule Express.APNS.Worker do
  use GenServer

  alias Express.Operations.LogMessage
  alias Express.APNS.JWTHolder
  alias Express.Network.HTTP2
  alias Express.APNS.PushMessage
  alias Express.Operations.APNS.Push
  alias Express.APNS.Connection, as: APNSConnection

  require Logger

  defmodule State do
    @type t :: %__MODULE__{
      connection: HTTP2.Connection.t,
      push_message: PushMessage.t,
      callback_fun: Express.callback_fun,
      async: boolean(),
      stop_at: pos_integer()
    }

    defstruct ~w(connection push_message callback_fun async stop_at)a
  end

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, {:ok, opts})

  def init({:ok, opts}) do
    connection = APNSConnection.new()

    if connection do
      {:ok, %State{connection: connection,
                   async: (opts[:async] in ["true", true]),
                   stop_at: shift_timer()}}
    else
      {:stop, :no_connection}
    end
  end

  def push(worker, push_message, opts, callback_fun) do
    GenServer.call(worker, {:push, push_message, opts, callback_fun}, 3000)
  end

  def handle_call({:push, push_message, _opts, callback_fun}, _from, %{async: true} = state) do
    if state.stop_at && state.stop_at <= Timex.to_unix(Timex.now()) do
      {:stop, :normal, {:error, :connection_down}, state}
    else
      if Process.alive?(state.connection.socket) do
        push_message
        |> push_params(state)
        |> Push.run!()

        new_state =
          state
          |> Map.put(:push_message, push_message)
          |> Map.put(:callback_fun, callback_fun)

        {:reply, :pushed, new_state}
      else
        {:stop, :normal, {:error, :connection_down}, state}
      end
    end
  end
  def handle_call({:push, push_message, _opts, callback_fun}, _from, %{async: false} = state) do
    if state.stop_at && state.stop_at <= Timex.to_unix(Timex.now()) do
      {:stop, :normal, {:error, :connection_down}, state}
    else
      if Process.alive?(state.connection.socket) do
        {headers, body} =
          push_message
          |> push_params(state)
          |> Push.run!()

        result = handle_response({headers, body}, state, callback_fun)

        new_state = Map.put(state, :stop_at, shift_timer())

        {:reply, {:ok, result}, new_state}
      else
        {:stop, :normal, {:error, :connection_down}, state}
      end
    end
  end

  def handle_info({:END_STREAM, stream},
                  %{connection: connection,
                    callback_fun: callback_fun} = state)
  do
    {:ok, {headers, body}} = HTTP2.get_response(connection, stream)
    handle_response({headers, body}, state, callback_fun)

    new_state = Map.put(state, :stop_at, shift_timer())

    {:noreply, new_state}
  end
  def handle_info(:timeout, state), do: {:stop, :normal, {:error, :timeout}, state}
  def handle_info(_, state), do: {:noreply, state}

  @spec push_params(PushMessage.t, State.t) :: Keyword.t
  defp push_params(push_message, %{connection: connection, async: async}) when is_map(connection) do
    if is_map(connection.ssl_config) do
      [
        push_message: push_message,
        connection: connection,
        async: async
      ]
    else
      [
        push_message: push_message,
        connection: connection,
        jwt: JWTHolder.get_jwt(),
        async: async
      ]
    end
  end

  @spec handle_response({list(), String.t}, State.t, Express.callback_fun) :: any()
  defp handle_response({headers, body} = _response, state, callback_fun) do
    result =
      case status = fetch_status(headers) do
        200 ->
          {:ok, %{status: status, body: body}}
        status ->
          error_reason = fetch_reason(body)
          log_error({status, error_reason}, state.push_message)

          {:error, %{status: status, body: body}}
      end

    if is_function(callback_fun) do
      callback_fun.(state.push_message, result)
    end

    result
  end
  defp handle_response(_, _, _), do: :nothing

  @spec fetch_status(list()) :: String.t | nil
  defp fetch_status([]), do: nil
  defp fetch_status([{":status", status} | _tail]), do: String.to_integer(status)
  defp fetch_status([_head | tail]), do: fetch_status(tail)
  defp fetch_status(_), do: nil

  @spec fetch_reason(String.t) :: String.t
  defp fetch_reason(nil), do: nil
  defp fetch_reason(""), do: ""
  defp fetch_reason([]), do: ""
  defp fetch_reason([body]), do: fetch_reason(body)
  defp fetch_reason(body) do
    {:ok, body} = Poison.decode(body)
    Macro.underscore(body["reason"])
  end

  @spec log_error({String.t, String.t}, PushMessage.t) :: :ok | {:error, any()}
  defp log_error({status, reason}, push_message) do
    error_message = """
    [APNS worker] APNS: #{inspect(reason)}[#{status}]\n#{inspect(push_message)}
    """

    LogMessage.run!(message: error_message, type: :warn)
  end

  @spec shift_timer() :: pos_integer()
  defp shift_timer do
    Timex.now() |> Timex.shift(seconds: 10) |> Timex.to_unix()
  end
end
