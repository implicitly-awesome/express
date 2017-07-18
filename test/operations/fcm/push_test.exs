defmodule Operations.FCM.PushTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Mock

  alias Express.Operations.FCM.Push
  alias Express.FCM.PushMessage

  @response_200 {:ok, %HTTPoison.Response{
    status_code: 200,
    body: ~S({"results":["everything is fine"]})
  }}
  @response_200_error {:ok, %HTTPoison.Response{
    status_code: 200,
    body: ~S({"results":[{"error":"oops"}, {"error":"oops2"}]})
  }}
  @response_401_error {:ok, %HTTPoison.Response{
    status_code: 401,
    body: ~S({"results":[{"error":"oops"}, {"error":"oops2"}]})
  }}
  @response_error {:ok, %HTTPoison.Response{
    status_code: 404,
    body: ~S({"results":[{"error":"oops"}, {"error":"oops2"}]})
  }}
  @error {:error, :unhappy}

  setup do
    registration_id = "your_registration_id"
    notification = %PushMessage.Notification{title: "Title", body: "Body"}
    push_message = %PushMessage{
      registration_ids: [registration_id],
      notification: notification,
      data: %{}
    }

    {:ok, push_message: push_message}
  end

  describe "with callback function provided" do
    test "invokes callback function on 200 ok", %{push_message: push_message} do
      with_mock HTTPoison, [post: fn(_, _, _) -> @response_200 end] do
        Push.run(
          push_message: push_message,
          opts: [],
          callback_fun: fn (_, result) ->
            assert result == {:ok, %{body: "{\"results\":[\"everything is fine\"]}", status: 200}}
          end
        )
      end
    end

    test "invokes callback function on 200 error",
         %{push_message: push_message} do
      with_mock HTTPoison, [post: fn(_, _, _) -> @response_200_error end] do
        Push.run(
          push_message: push_message,
          opts: [],
          callback_fun: fn (_, result) ->
            assert result == {:error, %{status: 200, body: "{\"results\":[{\"error\":\"oops\"}, {\"error\":\"oops2\"}]}"}}
          end
        )
      end
    end

    test "invokes callback function on 401 error",
         %{push_message: push_message} do
      with_mock HTTPoison, [post: fn(_, _, _) -> @response_401_error end] do
        Push.run(
          push_message: push_message,
          opts: [],
          callback_fun: fn (_, result) ->
            assert result == {:error, %{status: 401, body: "{\"results\":[{\"error\":\"oops\"}, {\"error\":\"oops2\"}]}"}}
          end
        )
      end
    end

    test "invokes callback function on error response",
         %{push_message: push_message} do
      with_mock HTTPoison, [post: fn(_, _, _) -> @response_error end] do
        Push.run(
          push_message: push_message,
          opts: [],
          callback_fun: fn (_, result) ->
            assert result == {:error, %{status: 404, body: "{\"results\":[{\"error\":\"oops\"}, {\"error\":\"oops2\"}]}"}}
          end
        )
      end
    end

    test "invokes callback function on HTTPoison error",
         %{push_message: push_message} do
      with_mock HTTPoison, [post: fn(_, _, _) -> @error end] do
        Push.run(
          push_message: push_message,
          opts: [],
          callback_fun: fn (_, result) ->
            assert result == {:error, {:http_error, :unhappy}}
          end
        )
      end
    end
  end

  describe "with callback function was not provided" do
    test "just sends push message",
         %{push_message: push_message} do

      headers = [
        {"Content-Type", "application/json"},
        {"Authorization", "key=your_api_key"}
      ]

      payload = Poison.encode!(push_message)

      with_mock HTTPoison, [post: fn(_, _, _) -> @error end] do
        Push.run(push_message: push_message, opts: [])

        assert called HTTPoison.post("https://fcm.googleapis.com/fcm/send",
                                     payload,
                                     headers)
      end
    end
  end
end
