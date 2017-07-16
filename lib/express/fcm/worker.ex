defmodule Express.FCM.Worker do
  @moduledoc """
  Incapsulates work with FCM logic. Exists temporary: until work with FCM finished.
  """

  use GenServer

  alias Express.FCM.PushMessage
  alias Express.Operations.LogMessage

  defmodule State do
    @moduledoc """
    Specifies FCM worker state structure.
    """

    @type t :: %__MODULE__{
      push_message: PushMessage.t,
      opts: Keyword.t,
      callback_fun: ((PushMessage.t, any()) -> any()) | nil
    }

    defstruct ~w(push_message opts callback_fun)a
  end

  @uri_path "https://fcm.googleapis.com/fcm/send"

  @spec start_link(State.t) :: {:ok, pid} |
                               :ignore |
                               {:error, {:already_started, pid} | any()}
  def start_link(state), do: GenServer.start_link(__MODULE__, {:ok, state})

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

  @doc """
  Returns api-key for FCM (resolved from provided `opts`).
  """
  @spec api_key_for(Keyword.t) :: String.t
  def api_key_for(opts \\ []) do
    opts[:api_key] || Application.get_env(:express, :fcm)[:api_key]
  end

  @doc """
  Sends push_message synchronously to FCM with specified api_key.
  Invokes callback_fun finction after response receive. 
  """
  @spec do_push(State.t) :: any()
  def do_push(%{push_message: push_message,
                opts: opts,
                callback_fun: callback_fun}) do
    api_key = api_key_for(opts)

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{api_key}"}
    ]

    payload = Poison.encode!(push_message)
    result = HTTPoison.post("#{@uri_path}", payload, headers)

    case result do
      {:ok, response = %HTTPoison.Response{status_code: 200 = status,
                                           body: body}} ->
        if Mix.env == :dev do
          LogMessage.run!(message: payload, type: :info)
          LogMessage.run!(message: inspect(response), type: :info)
        end

        handle_response(push_message, {status, body}, callback_fun)
      {:ok, %HTTPoison.Response{status_code: 401 = status, body: body}} ->
        error_message = "[FCM worker] Unauthorized API key."
        LogMessage.run!(message: error_message)

        if callback_fun do
          callback_fun.(push_message, {:error, %{status: status, body: body}})
        end
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        log_error({status, body}, push_message)

        if callback_fun do
          callback_fun.(push_message, {:error, %{status: status, body: body}})
        end
      {:error, error} ->
        error_message = """
        [FCM worker] HTTPoison could not handle a request.
        Error: #{inspect(error)}
        """
        LogMessage.run!(message: error_message)

        if callback_fun do
          callback_fun.(push_message, {:error, :http_error})
        end
      _ ->
        error_message = "[FCM worker] Unhandled error."
        LogMessage.run!(message: error_message)

        if callback_fun do
          callback_fun.(push_message, {:error, :unhandled_error})
        end
    end
  end
  def do_push(_state), do: :nothing

  @spec handle_response(PushMessage.t,
                        {String.t, String.t},
                        ((PushMessage.t, Express.push_result) -> any()) | nil) :: :ok
  defp handle_response(push_message, {status, body}, callback_fun) do
    errors =
      body
      |> Poison.decode!
      |> Map.get("results", [])
      |> Enum.map(&(handle_result(&1)))
      |> Enum.reject(&(&1 == :ok))

    result =
      if Enum.any?(errors) do
        Enum.each(errors, fn {:error, error_message} ->
          log_error({status, error_message}, push_message)
        end)

        {:error, %{status: status, body: body}}
      else
        {:ok, %{status: status, body: body}}
      end

    if callback_fun, do: callback_fun.(push_message, result)

    :ok
  end

  @spec handle_result(map()) :: :ok | {:error, String.t}
  defp handle_result(%{"error" => message}), do: {:error, message}
  defp handle_result(_), do: :ok

  @spec log_error({String.t, String.t}, PushMessage.t) :: :ok | {:error, any()}
  defp log_error({status, reason}, push_message) do
    error_message = """
    [FCM worker] FCM: #{inspect(reason)}[#{status}]\n#{inspect(push_message)}
    """

    LogMessage.run!(message: error_message, type: :warn)
  end
end
