defmodule Express.APNS.Worker do
  @moduledoc """
  Incapsulates work with APNS logic. Exists temporary: until work with APNS finished.
  """

  use GenServer
  alias Express.Operations.LogMessage

  alias Express.Network.HTTP2
  alias Express.APNS.{PushMessage, ConnectionHolder}
  alias Express.Operations.APNS.Push

  defmodule State do
    @moduledoc """
    Defines APNS worker state structure.
    """

    @type t :: %__MODULE__{
      connection: HTTP2.Connection.t,
      push_message: PushMessage.t,
      callback_fun: Express.callback_fun,
      delayed: boolean()
    }

    defstruct ~w(connection push_message callback_fun delayed)a
  end

  def start_link, do: start_link(:ok)
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok)

  def init(:ok) do
    connection = ConnectionHolder.connection()

    if connection do
      {:ok, %State{connection: connection}}
    else
      {:stop, :no_connection}
    end
  end

  @doc """
  Pushes a `push_message` via `worker` with specified `opts` and `callback_fun`.
  """
  @spec push(module(), PushMessage.t, Keyword.t, Express.callback_fun) :: reference() |
                                                                          :ok |
                                                                          :noconnect |
                                                                          :nosuspend |
                                                                          true
  def push(worker, push_message, opts, callback_fun) do
    Process.send(worker, {:push, push_message, opts, callback_fun}, [])
  end

  @doc """
  Pushes a `push_message` via `worker` with specified `opts` and `callback_fun`
  after a delay specified in the `opts`.
  """
  @spec push_after(module(), PushMessage.t, Keyword.t, Express.callback_fun) :: reference() |
                                                                                :ok |
                                                                                :noconnect |
                                                                                :nosuspend |
                                                                                true
  def push_after(worker, push_message, opts, callback_fun) do
    delay = (opts[:delay] || 1) * 1000
    Process.send_after(worker, {:push, push_message, opts, callback_fun}, delay)
  end

  def handle_info({:push, push_message, opts, callback_fun}, state) do
    Push.run!(
      push_message: push_message,
      connection: state.connection,
      opts: opts,
      callback_fun: callback_fun
    )

    new_state =
      state
      |> Map.put(:push_message, push_message)
      |> Map.put(:callback_fun, callback_fun)
      |> Map.put(:delayed, (opts[:delay] && opts[:delay] > 0))

    {:noreply, new_state}
  end

  def handle_info({:END_STREAM, stream},
                  %{connection: connection,
                    callback_fun: callback_fun,
                    delayed: delayed} = state) do
    {:ok, {headers, body}} = HTTP2.get_response(connection, stream)
    handle_response({headers, body}, state, callback_fun)

    if delayed do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  @spec handle_response({list(), String.t},
                        map(),
                        Express.callback_fun | nil) :: {:noreply, map()}
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
