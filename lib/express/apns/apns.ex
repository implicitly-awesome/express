defmodule Express.APNS do
  @moduledoc """
  APNS pusher. Conforms Express behaviour.
  """

  @behaviour Express

  alias Express.APNS.{Worker, PushMessage, DelayedPushes}

  @spec push(PushMessage.t, Keyword.t, Express.callback_fun | nil) :: {:noreply, map()}
  def push(push_message, opts \\ [], callback_fun \\ nil) do
    if opts[:delay] do
      delayed_push(push_message, opts, callback_fun)
    else
      instant_push(push_message, opts, callback_fun)
    end
  end

  @spec instant_push(PushMessage.t, Keyword.t, Express.callback_fun) :: {:noreply, map()}
  defp instant_push(push_message, opts, callback_fun) do
    :poolboy.transaction(pool_name(), fn(worker) ->
      Worker.push(worker, push_message, opts, callback_fun)
    end)
  end

  @spec delayed_push(PushMessage.t, Keyword.t, Express.callback_fun) :: {:noreply, map()}
  defp delayed_push(push_message, opts, callback_fun) do
    DelayedPushes.add(push_message, opts, callback_fun)
  end

  @spec pool_name() :: atom()
  defp pool_name, do: Express.Supervisor.apns_pool_name()
end
