defmodule Express.APNS.Worker do
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

  @type push_result :: {:ok, %{status: pos_integer(), body: any()}} |
                       {:error, %{status: pos_integer(), body: any()}}

  @spec start_link(State.t) :: {:ok, pid} | :ignore | {:error, {:already_started, pid()} | any()}
  def start_link(state), do: GenServer.start_link(__MODULE__, {:ok, state})

  def init({:ok, state}), do: {:ok, state}

  @doc "Sends push message with `worker` and provided `delay`"
  @spec push(pid(), pos_integer()) :: reference() | :ok | :noconnect | :nosuspend | true
  def push(worker, delay) when is_integer(delay) do
    if delay && delay >= 1 do
      Process.send_after(worker, :push, delay * 1000)
    else
      Process.send(worker, :push, [])
    end
  end
  def push(worker, _delay), do: Process.exit(worker, :normal)

  def handle_info(:push, %{connection: _,
                           push_message: _,
                           opts: _,
                           callback_fun: _} = state) do
    do_push(state)

    {:noreply, state}
  end

  def handle_info({:END_STREAM, stream},
                  %{connection: connection,
                    callback_fun: callback_fun} = state) do
    {:ok, {headers, body}} = HTTP2.get_response(connection, stream)

    handle_response({headers, body}, state, callback_fun)

    Process.send(self(), :kill_worker, [])
    {:noreply, state}
  end

  @spec log_error({String.t, String.t}, PushMessage.t) :: :ok | {:error, any()}
  defp log_error({status, reason}, push_message) do
    error_message = """
    [APNS worker] #{inspect(reason)}[#{status}]\n#{inspect(push_message)}
    """
    LogMessage.run!(message: error_message, type: :warn)
  end

  @spec do_push(%{push_message: PushMessage.t, connection: Connection.t}) :: {:noreply, map()}
  defp do_push(%{push_message: %{token: token} = push_message, connection: connection}) do
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

  @spec handle_response({list(), String.t}, map(), ((PushMessage.t, push_result) -> any()) | nil) :: {:noreply, map()}
  defp handle_response({headers, body} = response, state, callback_fun)
         when (is_function(callback_fun) or is_nil(callback_fun)) do
    case status = fetch_status(headers) do
      200 ->
        if Mix.env == :dev, do: LogMessage.run!(message: inspect(response), type: :info)

        if callback_fun, do: callback_fun.(state.push_message, {:ok, %{status: status, body: body}})
      status ->
        error_reason = body |> fetch_reason
        {status, error_reason} |> log_error(state.push_message)
        if callback_fun, do: callback_fun.(state.push_message, {:error, %{status: status, body: body}})
    end

    Process.exit(self(), :normal)
  end
  defp handle_response(_, _, _), do: Process.exit(self(), :normal)

  @spec fetch_reason(String.t) :: String.t
  defp fetch_reason(nil), do: nil
  defp fetch_reason(""),  do: ""
  defp fetch_reason(body) do
    {:ok, body} = Poison.decode(body)
    Macro.underscore(body["reason"])
  end
end
