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

  @doc "Normalizes a push message `struct` to a map acceptable by APNS"
  @spec to_apns_map(__MODULE__.t) :: map()
  def to_apns_map(struct) do
    map =
      if struct |> Map.keys |> Enum.member?(:__struct__) do
        Map.from_struct(struct)
      else
        struct
      end

    %{
      "token" => map.token,
      "topic" => map.topic,
      "aps" => Aps.to_apns_map(map.aps),
      "apple-watch" => map.apple_watch,
      "acme" => map.acme
    }
  end
end
