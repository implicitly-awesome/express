defmodule Express.APNS.Worker do
  @moduledoc """
  Incapsulates work with APNS logic. Exists temporary: until work with APNS finished.
  """

  defmodule State do
    @moduledoc """
    Defines APNS worker state structure.
    """

    @type t :: %__MODULE__{connection: HTTP2.Connection.t,
                           push_message: APNS.PushMessage.t,
                           opts: Keyword.t,
                           callback_fun: fun()}

    defstruct ~w(connection push_message opts callback_fun)a
  end

  use GenServer
  alias Express.Operations.LogMessage

  alias Express.Network.HTTP2
  alias Express.Network.HTTP2.Connection
  alias Express.APNS.PushMessage

  @spec start_link(HTTP2.Connection.t, State.t) :: {:ok, pid} |
                                                   :ignore |
                                                   {:error, {:already_started, pid()} | any()}
  def start_link(connection, state) do
    state = %State{state | connection: connection}
    GenServer.start_link(__MODULE__, {:ok, state})
  end

  def init({:ok, state}), do: {:ok, state}

  @doc """
  Pushes a push message via `worker` with specified `delay`.
  """
  @spec push(pid(), pos_integer()) :: reference() |
                                      :ok |
                                      :noconnect |
                                      :nosuspend |
                                      true
  def push(worker, delay \\ 0)
  def push(worker, delay) when is_integer(delay) do
    if delay >= 1 do
      Process.send_after(worker, :push, delay * 1000)
    else
      Process.send(worker, :push, [])
    end
  end
  def push(worker, _delay) do
    Process.exit(worker, :normal)
  end

  def handle_info(:push, state) do
    do_push(state)
    {:stop, :normal, state}
  end

  def handle_info({:END_STREAM, stream},
                  %{connection: connection,
                    callback_fun: callback_fun} = state) do
    {:ok, {headers, body}} = HTTP2.get_response(connection, stream)

    handle_response({headers, body}, state, callback_fun)

    {:stop, :normal, state}
  end

  @spec log_error({String.t, String.t}, PushMessage.t) :: :ok | {:error, any()}
  defp log_error({status, reason}, push_message) do
    error_message = """
    [APNS worker] #{inspect(reason)}[#{status}]\n#{inspect(push_message)}
    """
    LogMessage.run!(message: error_message, type: :warn)
  end

  @spec do_push(%{push_message: PushMessage.t, connection: Connection.t}) :: {:noreply, map()}
  defp do_push(%{push_message: %{token: token} = push_message,
                 connection: connection}) do
    {:ok, json} = Poison.encode(push_message)

    if Mix.env == :dev, do: LogMessage.run!(message: json, type: :info)

    headers = [
      {":method", "POST"},
      {":path", "/3/device/#{token}"},
      {"content-length", "#{byte_size(json)}"}
    ]

    headers =
      if push_message.topic do
        headers ++ [{"apns-topic", push_message.topic}]
      else
        headers
      end

    HTTP2.send_request(connection, headers, json)
  end

  @spec fetch_status(list()) :: String.t | nil
  defp fetch_status([]), do: nil
  defp fetch_status([{":status", status} | _tail]), do: String.to_integer(status)
  defp fetch_status([_head | tail]), do: fetch_status(tail)
  defp fetch_status(_), do: nil

  @spec handle_response({list(), String.t},
                        map(),
                        ((PushMessage.t, Express.push_result) -> any()) | nil) :: {:noreply, map()}
  defp handle_response({headers, body} = response, state, callback_fun)
       when (is_function(callback_fun) or is_nil(callback_fun)) do
    result = 
      case status = fetch_status(headers) do
        200 ->
          if Mix.env == :dev do
            LogMessage.run!(message: inspect(response), type: :info)
          end

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

  @spec fetch_reason(String.t) :: String.t
  defp fetch_reason(nil), do: nil
  defp fetch_reason(""),  do: ""
  defp fetch_reason(body) do
    {:ok, body} = Poison.decode(body)
    Macro.underscore(body["reason"])
  end
end
