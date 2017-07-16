defmodule Express.FCM.PushMessage do
  @moduledoc """
  Defines FCM push message structure.
  """

  @derive [Poison.Encoder]

  alias Express.FCM.PushMessage

  @type t :: %__MODULE__{to: String.t,
                         registration_ids: [String.t],
                         priority: String.t,
                         content_available: boolean(),
                         collapse_key: String.t,
                         data: map(),
                         notification: PushMessage.Notification.t}

  defstruct to: nil,
            registration_ids: nil,
            priority: "normal",
            content_available: nil,
            collapse_key: nil,
            data: %{},
            notification: nil
end
