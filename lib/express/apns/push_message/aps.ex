defmodule Express.APNS.PushMessage.Aps do
  @moduledoc """
  Defines APNS push message aps structure.
  """

  alias Express.APNS.PushMessage.Alert
  alias Express.Helpers.MapHelper

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{content_available: pos_integer(),
                         mutable_content: pos_integer(),
                         badge: pos_integer(),
                         sound: String.t,
                         category: String.t,
                         thread_id: String.t,
                         alert: Alert.t | String.t}

  defstruct ~w(
    content_available
    mutable_content
    badge
    sound
    category
    thread_id
    alert
  )a

  @doc "Normalizes an aps `struct` to a map acceptable by APNS"
  @spec to_apns_map(__MODULE__.t) :: map()
  def to_apns_map(struct) do
    struct
    |> Map.from_struct()
    |> Enum.reduce(%{}, fn({key, value}, result) ->
         if valid_key?(key, value) do
           Map.put(result, key, value)
         else
           result
         end
       end)
    |> MapHelper.dasherize_keys()
  end

  defp valid_key?(:content_available, value), do: is_integer(value)
  defp valid_key?(:mutable_content, value), do: is_integer(value)
  defp valid_key?(:badge, value), do: is_integer(value)
  defp valid_key?(:sound, value), do: is_binary(value) && String.length(value) > 0
  defp valid_key?(:category, value), do: is_binary(value) && String.length(value) > 0
  defp valid_key?(:thread_id, value), do: is_binary(value) && String.length(value) > 0
  defp valid_key?(_, _), do: true
end
