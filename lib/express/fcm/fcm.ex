defmodule Express.FCM do
  @moduledoc """
  FCM pusher. Conforms Express behaviour.
  """

  @behaviour Express

  alias Express.FCM

  @spec push(FCM.PushMessage.t, Keyword.t, ((FCM.PushMessage.t, any()) -> any()) | nil) :: {:noreply, map()}
  def push(push_message, opts \\ [], callback_fun \\ nil) do
    do_push(push_message, opts, callback_fun)
  end

  @spec do_push(FCM.PushMessage.t, Keyword.t, fun()) :: {:noreply, map()}
  defp do_push(push_message, opts, callback_fun) do
    :poolboy.transaction(pool_name(), fn(supervisor) ->
      FCM.Supervisor.push(supervisor, push_message, opts, callback_fun)
    end)
  end

  @spec pool_name() :: atom()
  defp pool_name, do: Express.Application.fcm_pool_name()
end
