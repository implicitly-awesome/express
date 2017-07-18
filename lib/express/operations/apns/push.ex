defmodule Express.Operations.APNS.Push do
  @moduledoc """
  Sends push_message asynchronously to APNS with specified api_key.
  Invokes callback_fun function after response receive. 
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
  defp do_push(%{token: token} = push_message, connection) do
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
end
