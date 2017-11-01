defmodule Express.Operations.APNS.Push do
  @moduledoc """
  Sends push_message synchronously to APNS.
  Invokes callback_fun function after response receive. 

  [Exop](https://github.com/madeinussr/exop) library operation.

  Takes parameters:
  * `connection` (a connection to send push message through)
  * `jwt` (a JWT for a request (if you don't use ssl config))
  * `push_message` (a push message to send)
  """

  use Exop.Operation
  require Logger

  alias Express.Operations.LogMessage
  alias Express.Network.HTTP2
  alias Express.APNS.PushMessage

  parameter :connection, struct: %HTTP2.Connection{}, required: true
  parameter :jwt, type: :string
  parameter :push_message, struct: %PushMessage{}, required: true
  parameter :async, type: :boolean, default: true

  def process(contract) do
    connection = contract[:connection]
    jwt = contract[:jwt]
    push_message = contract[:push_message]
    async = contract[:async]

    do_push(push_message, connection, jwt, async)
  end

  defp do_push(push_message, connection, jwt, async) do
    {:ok, payload} =
      push_message
      |> PushMessage.to_apns_map()
      |> Poison.encode()

    if Application.get_env(:express, :environment) == :dev do
      LogMessage.run!(message: payload, type: :info)
    end

    headers = headers_for(push_message, payload, jwt)

    if async do
      HTTP2.send_request(connection, headers, payload)
    else
      HTTP2.sync_request(connection, headers, payload)
    end
  end

  defp headers_for(push_message, payload, nil) do
    headers = [
      {":method", "POST"},
      {":path", "/3/device/#{push_message.token}"},
      {"content-length", "#{byte_size(payload)}"}
    ]

    if push_message.topic do
      headers ++ [{"apns-topic", push_message.topic}]
    else
      headers
    end
  end
  defp headers_for(push_message, payload, jwt) do
    headers_for(push_message, payload, nil) ++ [{"authorization", "bearer #{jwt}"}]
  end
end
