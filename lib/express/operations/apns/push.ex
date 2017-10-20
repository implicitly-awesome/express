defmodule Express.Operations.APNS.Push do
  @moduledoc """
  Sends push_message synchronously to APNS.
  Invokes callback_fun function after response receive. 

  [Exop](https://github.com/madeinussr/exop) library operation.

  Takes parameters:
  * `connection` (a connection to send push message through)
  * `push_message` (a push message to send)
  * `opts` (options)
  * `callback_fun` (callback function to invoke on response)
  """

  use Exop.Operation
  require Logger

  alias Express.Operations.LogMessage
  alias Express.Network.HTTP2
  alias Express.APNS.PushMessage

  parameter :connection, struct: %HTTP2.Connection{}, required: true
  parameter :push_message, struct: %PushMessage{}, required: true
  parameter :opts, type: :list, default: []
  parameter :callback_fun, type: :function

  def process(contract) do
    connection = contract[:connection]
    push_message = contract[:push_message]

    do_push(push_message, connection)
    true
  end

  @spec do_push(PushMessage.t, HTTP2.Connection.t) :: {:noreply, map()}
  defp do_push(%{token: token} = push_message, %{ssl_config: ssl_config} = connection)
       when is_map(ssl_config) do
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
  defp do_push(%{token: token} = push_message, %{jwt: jwt} = connection)
       when is_binary(jwt) do
    {:ok, json} = Poison.encode(push_message)

    if Mix.env == :dev, do: LogMessage.run!(message: json, type: :info)

    headers = [
      {":method", "POST"},
      {":path", "/3/device/#{token}"},
      {"content-length", "#{byte_size(json)}"},
      {"authorization", "bearer #{jwt}"}
    ]

    headers =
      if push_message.topic do
        headers ++ [{"apns-topic", push_message.topic}]
      else
        headers
      end

    HTTP2.send_request(connection, headers, json)
  end

  defp do_push(_push_message, _connection), do: {:error, :malformed_connection}
end
