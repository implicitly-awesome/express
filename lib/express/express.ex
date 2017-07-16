defmodule Express do
  @moduledoc """
  Defines the interface of Express pusher for certain provider (APNS, FCM)
  """

  alias Express.APNS
  alias Express.FCM

  @doc """
  Pushes a message with options and callback function (which are optional).
  Returns a response from a provider (via callback function).
  """
  @callback push(APNS.PushMessage.t | FCM.PushMessage.t,
                 Keyword.t,
                 ((APNS.PushMessage.t | FCM.PushMessage.t, any()) -> any()) | nil) :: {:noreply, map()}
end
