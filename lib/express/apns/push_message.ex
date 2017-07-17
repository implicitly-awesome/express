defmodule Express.APNS.PushMessage do
  @moduledoc """
  Defines APNS push message structure.
  """

  alias Express.APNS.PushMessage.Aps

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{token: String.t,
                         topic: String.t,
                         aps: Aps.t,
                         apple_watch: map(),
                         acme: map()}

  defstruct [token: nil,
             topic: nil,
             aps: nil,
             apple_watch: %{},
             acme: %{}]
end
