defmodule Operations.APNS.PushTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Mock

  alias Express.Operations.APNS.Push
  alias Express.APNS.{PushMessage, SSLConfig}
  alias Express.Network.HTTP2

  @ok_body "everything is ok"

  setup do
    token = "device_token"
    alert = %PushMessage.Alert{title: "Title", body: "Body"}
    aps = %PushMessage.Aps{alert: alert}
    push_message = %PushMessage{token: token, aps: aps, acme: %{}}
    ssl_config = SSLConfig.new()
    connection =
      %HTTP2.Connection{client: nil,
                        provider: :apns,
                        socket: nil,
                        ssl_config: ssl_config}

    {:ok, connection: connection, push_message: push_message}
  end

  test "sends a request to apns",
       %{connection: connection, push_message: push_message} do
    with_mock HTTP2, [send_request: fn(_, _, _) -> @ok_body end] do
      {:ok, json} = Poison.encode(push_message)

      headers = [
        {":method", "POST"},
        {":path", "/3/device/#{push_message.token}"},
        {"content-length", "#{byte_size(json)}"}
      ]

      headers =
        if push_message.topic do
          headers ++ [{"apns-topic", push_message.topic}]
        else
          headers
        end

      Push.run(connection: connection, push_message: push_message)

      assert called HTTP2.send_request(connection, headers, json)
    end
  end
end
