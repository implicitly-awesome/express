defmodule Express.FCM.Client do
  @moduledoc """
  Incapsulates work with FCM logic. Exists temporary: until work with FCM finished.
  """

  use GenServer

  alias Express.FCM.PushMessage
  alias Express.Operations.LogMessage

  defmodule State do
    @moduledoc """
    Specifies FCM client state structure.
    """

    @type t :: %__MODULE__{push_message: PushMessage.t,
                           opts: Keyword.t,
                           callback_fun: ((PushMessage.t, any()) -> any()) | nil}

    defstruct ~w(push_message opts callback_fun)a
  end

  @type push_result :: {:ok, %{status: pos_integer(), body: any()}} |
                       {:error, %{status: pos_integer(), body: any()}} |
                       {:error, :http_error} |
                       {:error, :unhandled_error}

  @uri_path "https://fcm.googleapis.com/fcm/send"

  @spec start_link(Keyword.t) :: {:ok, pid} | :ignore | {:error, {:already_started, pid} | any()}
  def start_link([]), do: GenServer.start_link(__MODULE__, :ok)
  def start_link(state), do: GenServer.start_link(__MODULE__, state)

  @spec init(:ok) :: {:ok, State.t}
  def init(:ok), do: {:ok, %State{}}

  @spec init(Keyword.t) :: {:ok, State.t}
  def init(state), do: {:ok, struct(State, state)}

  @doc """
  Sends `push_message` via `client`.
  Invokes `callback_fun` function after a response receive.
  """
  @spec push(pid(), PushMessage.t, Keyword.t | nil, ((PushMessage.t, push_result) -> any()) | nil) :: {:noreply, map()}
  def push(client, push_message = %PushMessage{}, opts \\ %{}, callback_fun \\ nil) do
    GenServer.cast(client, {:push, push_message, opts, callback_fun})
  end

  def handle_cast({:push, push_message, opts, callback_fun}, state) do
    state =
      state
      |> Map.put(:push_message, push_message)
      |> Map.put(:opts, opts)
      |> Map.put(:callback_fun, callback_fun)

    if opts[:delay] && opts[:delay] >= 1 do
      {:ok, background_pid} = __MODULE__.start_link(Map.to_list(state))
      Process.send_after(background_pid, :delayed_push, opts[:delay] * 1000)
    else
      do_push(push_message, api_key_for(opts), callback_fun)
      # send(self(), :stop_client)
    end

    {:noreply, state}
  end

  def handle_info(:stop_client, state) do
    {:stop, :normal, state}
  end

  def handle_info(:delayed_push, %{push_message: push_message, opts: opts, callback_fun: callback_fun} = state) do
    do_push(push_message, api_key_for(opts), callback_fun)
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
  Sends `push_message` synchronously to FCM with specified `api_key`.
  Invokes `callback_fun` finction after response receive. 
  """
  @spec do_push(PushMessage.t, String.t, ((PushMessage.t, push_result) -> any()) | nil) :: push_result
  def do_push(push_message, api_key, callback_fun \\ nil) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{api_key}"}
    ]

    payload = Poison.encode!(push_message)
    result = HTTPoison.post("#{@uri_path}", payload, headers)

    case result do
      {:ok, response = %HTTPoison.Response{status_code: 200 = status, body: body}} ->
        if Mix.env == :dev do
          LogMessage.run!(message: payload, type: :info)
          LogMessage.run!(message: inspect(response), type: :info)
        end

        handle_response(push_message, {status, body}, callback_fun)
      {:ok, %HTTPoison.Response{status_code: 401 = status, body: body}} ->
        error_message = "[FCM client] Unauthorized API key."
        LogMessage.run!(message: error_message)

        if callback_fun, do: callback_fun.(push_message, {:error, %{status: status, body: body}})
        {:error, :unauthorized}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        log_error({status, body}, push_message)
        if callback_fun, do: callback_fun.(push_message, {:error, %{status: status, body: body}})
        {:error, %{status: status, body: body}}
      {:error, error} ->
        error_message = """
        [FCM client] HTTPoison could not handle a request.
        Error: #{inspect(error)}
        """
        LogMessage.run!(message: error_message)

        if callback_fun, do: callback_fun.(push_message, {:error, :http_error})
        {:error, :http_error}
      _ ->
        error_message = "[FCM client] Unhandled error."
        LogMessage.run!(message: error_message)

        if callback_fun, do: callback_fun.(push_message, {:error, :unhandled_error})
        {:error, :unhandled_error}
    end
  end

  @spec handle_response(PushMessage.t,
                        {String.t, String.t},
                        ((PushMessage.t, push_result) -> any()) | nil) :: {:ok, %{status: String.t, body: String.t}} |
                                                                          {:error, %{status: String.t, body: String.t}}
  defp handle_response(push_message, {status, body}, callback_fun) do
    errors =
      body
      |> Poison.decode!
      |> Map.get("results", [])
      |> Enum.map(&(handle_result(&1)))
      |> Enum.reject(&(&1 == :ok))

    if Enum.any?(errors) do
      Enum.each(errors, fn {:error, error_message} -> log_error({status, error_message}, push_message) end)
      if callback_fun, do: callback_fun.(push_message, {:error, %{status: status, body: body}})

      {:error, %{status: status, body: body}}
    else
      if callback_fun, do: callback_fun.(push_message, {:ok, %{status: status, body: body}})

      {:ok, %{status: status, body: body}}
    end
  end

  @spec handle_result(map()) :: :ok | {:error, String.t}
  defp handle_result(%{"error" => message}), do: {:error, message}
  defp handle_result(_), do: :ok

  @spec log_error({String.t, String.t}, PushMessage.t) :: :ok | {:error, any()}
  defp log_error({status, reason}, push_message) do
    error_message = """
    [FCM client] FCM: #{inspect(reason)}[#{status}]\n#{inspect(push_message)}
    """

    LogMessage.run!(message: error_message, type: :warn)
  end
end
