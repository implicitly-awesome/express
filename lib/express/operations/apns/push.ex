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
  parameter :jwt, type: :string
  parameter :push_message, struct: %PushMessage{}, required: true

  def process(contract) do
    connection = contract[:connection]
    jwt = contract[:jwt]
    push_message = contract[:push_message]

    do_push(push_message, connection, jwt)
  end

  defp do_push(%{token: token} = push_message, connection, nil) do
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
  defp do_push(%{token: token} = push_message, connection, jwt) when is_binary(jwt) do
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
  defp do_push(_push_message, _connection, _jwt), do: {:error, :malformed_connection}
end
