defmodule Express.APNS do
  @behaviour Express

  alias Express.PushRequests.Supervisor
  alias Express.PushRequests.Adder
  alias Express.APNS.{PushMessage, DelayedPushes}

  @spec push(PushMessage.t, Keyword.t, Express.callback_fun | nil) :: {:noreply, map()}
  def push(push_message, opts \\ [], callback_fun \\ nil) do
    if is_integer(opts[:delay]) && opts[:delay] > 0 do
      delayed_push(push_message, opts, callback_fun)
    else
      instant_push(push_message, opts, callback_fun)
    end
  end

  @spec instant_push(PushMessage.t, Keyword.t, Express.callback_fun) :: {:noreply, map()}
  defp instant_push(push_message, opts, callback_fun) do
    :poolboy.transaction(buffer_adders_pool_name(), fn(adder) ->
      Adder.add(adder, push_message, opts, callback_fun)
    end)
  end

  @spec delayed_push(PushMessage.t, Keyword.t, Express.callback_fun) :: {:noreply, map()}
  defp delayed_push(push_message, opts, callback_fun) do
    DelayedPushes.add(push_message, opts, callback_fun)
  end

  @spec buffer_adders_pool_name() :: atom()
  defp buffer_adders_pool_name, do: Supervisor.buffer_adders_pool_name()
end
