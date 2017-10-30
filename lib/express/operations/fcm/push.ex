defmodule Express.Operations.FCM.Push do
  @moduledoc """
  Sends push_message synchronously to FCM.
  Invokes callback_fun function after response receive. 

  [Exop](https://github.com/madeinussr/exop) library operation.

  Takes parameters:
  * `push_message` (a push message to send)
  * `opts` (options)
  * `callback_fun` (callback function to invoke on response)
  """

  use Exop.Operation
  require Logger

  alias Express.Configuration
  alias Express.Operations.LogMessage
  alias Express.FCM.PushMessage

  @uri_path "https://fcm.googleapis.com/fcm/send"

  parameter :push_message, struct: %PushMessage{}, required: true
  parameter :opts, type: :list, default: []
  parameter :callback_fun, type: :function

  def process(contract) do
    push_message = contract[:push_message]
    opts = contract[:opts]
    callback_fun = contract[:callback_fun]

    result = do_push(push_message, opts)

    if callback_fun, do: callback_fun.(push_message, result)

    true
  end

  @spec do_push(PushMessage.t, Keyword.t) ::
    {:ok, %{status: pos_integer(), body: String.t}} |
    {:error, %{status: pos_integer(), body: String.t}} |
    {:error, {:http_error, any()}} |
    {:error, :unhandled_error}
  defp do_push(push_message, opts) do
    api_key = api_key_for(opts)

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{api_key}"}
    ]

    payload = Poison.encode!(push_message)

    case HTTPoison.post("#{@uri_path}", payload, headers) do
      {:ok, response = %HTTPoison.Response{status_code: 200 = status,
                                           body: body}} ->
        if Mix.env == :dev do
          LogMessage.run!(message: payload, type: :info)
          LogMessage.run!(message: inspect(response), type: :info)
        end

        handle_response(push_message, {status, body})
      {:ok, %HTTPoison.Response{status_code: 401 = status, body: body}} ->
        error_message = "[FCM worker] Unauthorized API key."
        LogMessage.run!(message: error_message)
        {:error, %{status: status, body: body}}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        log_error({status, body}, push_message)
        {:error, %{status: status, body: body}}
      {:error, error} ->
        error_message = """
        [FCM worker] HTTPoison could not handle a request.
        Error: #{inspect(error)}
        """
        LogMessage.run!(message: error_message)
        {:error, {:http_error, error}}
      _ ->
        error_message = "[FCM worker] Unhandled error."
        LogMessage.run!(message: error_message)
        {:error, :unhandled_error}
    end
  end

  @spec api_key_for(Keyword.t) :: String.t
  defp api_key_for(opts) do
    opts[:api_key] || Configuration.FCM.api_key()
  end

  @spec handle_response(PushMessage.t, {String.t, String.t}) :: :ok
  defp handle_response(push_message, {status, body}) do
    errors =
      body
      |> Poison.decode!
      |> Map.get("results", [])
      |> Enum.map(&(handle_result(&1)))
      |> Enum.reject(&(&1 == :ok))

    if Enum.any?(errors) do
      Enum.each(errors, fn {:error, error_message} ->
        log_error({status, error_message}, push_message)
      end)

      {:error, %{status: status, body: body}}
    else
      {:ok, %{status: status, body: body}}
    end
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
