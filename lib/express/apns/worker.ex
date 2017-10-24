defmodule Express.APNS.Worker do
  use GenServer

  alias Express.Operations.LogMessage
  alias Express.APNS.JWTHolder
  alias Express.Network.HTTP2
  alias Express.APNS.PushMessage
  alias Express.Operations.APNS.Push
  alias Express.APNS.Connection, as: APNSConnection

  defmodule State do
    @type t :: %__MODULE__{
      connection: HTTP2.Connection.t,
      push_message: PushMessage.t,
      callback_fun: Express.callback_fun
    }

    defstruct ~w(connection push_message callback_fun)a
  end

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok)

  def init(:ok) do
    connection = APNSConnection.new()

    if connection do
      {:ok, %State{connection: connection}}
    else
      {:stop, :no_connection}
    end
  end

  def push(worker, push_message, opts, callback_fun) do
    GenServer.call(worker, {:push, push_message, opts, callback_fun})
  end

  def handle_call({:push, push_message, _opts, callback_fun}, _from, state) do
    params =
      if is_map(state.connection.ssl_config) do
        [
          push_message: push_message,
          connection: state.connection
        ]
      else
        [
          push_message: push_message,
          connection: state.connection,
          jwt: JWTHolder.get_jwt()
        ]
      end

    Push.run!(params)

    new_state =
      state
      |> Map.put(:push_message, push_message)
      |> Map.put(:callback_fun, callback_fun)

    {:reply, :ok, new_state}
  end

  def handle_info({:END_STREAM, stream},
                  %{connection: connection,
                    callback_fun: callback_fun} = state) do
    {:ok, {headers, body}} = HTTP2.get_response(connection, stream)
    handle_response({headers, body}, state, callback_fun)

    {:noreply, state}
  end

  defp handle_response({headers, body} = _response, state, callback_fun)
       when (is_function(callback_fun) or is_nil(callback_fun)) do
    result =
      case status = fetch_status(headers) do
        200 ->
          {:ok, %{status: status, body: body}}
        status ->
          error_reason = fetch_reason(body)
          log_error({status, error_reason}, state.push_message)

          {:error, %{status: status, body: body}}
      end

    if callback_fun do
      callback_fun.(state.push_message, result)
    end
  end
  defp handle_response(_, _, _), do: :nothing

  @spec fetch_status(list()) :: String.t | nil
  defp fetch_status([]), do: nil
  defp fetch_status([{":status", status} | _tail]), do: String.to_integer(status)
  defp fetch_status([_head | tail]), do: fetch_status(tail)
  defp fetch_status(_), do: nil

  @spec fetch_reason(String.t) :: String.t
  defp fetch_reason(nil), do: nil
  defp fetch_reason(""),  do: ""
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
end
