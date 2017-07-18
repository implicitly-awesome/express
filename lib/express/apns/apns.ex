defmodule Express.APNS do
  @moduledoc """
  APNS pusher. Conforms Express behaviour.
  """

  @behaviour Express

  alias Express.APNS
  alias Express.APNS.Worker

  @spec push(APNS.PushMessage.t, Keyword.t, Express.callback_fun | nil) ::
    {:noreply, map()}
  def push(push_message, opts \\ [], callback_fun \\ nil) do
    do_push(push_message, opts, callback_fun)
  end

  @spec do_push(APNS.PushMessage.t, Keyword.t, fun()) :: {:noreply, map()}
  defp do_push(push_message, opts, callback_fun) do
    :poolboy.transaction(pool_name(), fn(supervisor) ->
      APNS.Supervisor.push(supervisor, Worker, push_message, opts, callback_fun)
    end)
  end

  @spec pool_name() :: atom()
  defp pool_name, do: Express.Application.apns_pool_name()
end
