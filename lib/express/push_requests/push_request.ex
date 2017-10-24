defmodule Express.PushRequests.PushRequest do
  alias Express.APNS.PushMessage, as: APNSPushMessage
  alias Express.FCM.PushMessage, as: FCMPushMessage

  @type t :: %__MODULE__{push_message: APNSPushMessage.t | FCMPushMessage.t,
                         opts: Keyword.t,
                         callback_fun: Express.callback_fun}

  defstruct ~w(push_message opts callback_fun)a
end
