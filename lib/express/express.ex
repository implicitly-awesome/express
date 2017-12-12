defmodule Express do
  @moduledoc """
  Library for sending push notifications.
  Supports Apple APNS and Google FCM services.
  """

  alias Express.APNS
  alias Express.FCM

  @type push_result :: {:ok, %{id: any(), status: pos_integer(), body: any()}} |
                        {:error, %{id: any(), status: pos_integer(), body: any()}}

  @type callback_fun :: ((PushMessage.t, Express.push_result) -> any())

  @doc """
  Pushes a message with options and callback function (which are optional).
  Returns a response from a provider (via callback function).
  """
  @callback push(APNS.PushMessage.t | FCM.PushMessage.t,
                 Keyword.t,
                 callback_fun | nil) :: {:noreply, map()}
end
