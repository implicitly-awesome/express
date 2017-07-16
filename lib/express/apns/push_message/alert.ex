defmodule Express.APNS.PushMessage.Alert do
  @moduledoc """
  Defines APNS push message alert structure.
  """

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{title: String.t, body: String.t}

  defstruct ~w(title body)a
end
