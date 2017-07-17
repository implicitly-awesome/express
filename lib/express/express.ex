defmodule Express do
  @moduledoc """
  Defines the interface of Express pusher for certain provider (APNS, FCM)
  """

  alias Express.APNS
  alias Express.FCM

  @type push_result :: {:ok, %{status: pos_integer(), body: any()}} |
                        {:error, %{status: pos_integer(), body: any()}}

  @type callback_fun :: ((PushMessage.t, Express.push_result) -> any())

  @doc """
  Pushes a message with options and callback function (which are optional).
  Returns a response from a provider (via callback function).
  """
  @callback push(APNS.PushMessage.t | FCM.PushMessage.t,
                 Keyword.t,
                 callback_fun | nil) :: {:noreply, map()}
end
