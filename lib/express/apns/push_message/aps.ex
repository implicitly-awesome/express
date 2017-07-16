defmodule Express.APNS.PushMessage.Aps do
  @moduledoc """
  Defines APNS push message aps structure.
  """

  alias Express.APNS.PushMessage.Alert

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{content_available: pos_integer(),
                         mutable_content: pos_integer(),
                         badge: pos_integer(),
                         sound: String.t,
                         category: String.t,
                         alert: Alert.t | String.t}

  defstruct ~w(
    content_available
    mutable_content
    badge
    sound
    category
    alert
  )a
end
