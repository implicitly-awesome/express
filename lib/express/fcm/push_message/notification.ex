defmodule Express.FCM.PushMessage.Notification do
  @moduledoc """
  Defines FCM push message's notification structure.
  """

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{title: String.t,
                         body: String.t,
                         icon: String.t,
                         sound: String.t,
                         click_action: String.t,
                         badge: pos_integer(),
                         category: String.t}

  defstruct [:title, :body, :icon, :sound, :click_action, :badge, :category]
end
