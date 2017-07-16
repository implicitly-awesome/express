defmodule Express.APNS do
  @moduledoc """
  APNS pusher. Conforms Express behaviour.
  """

  @behaviour Express

  alias Express.APNS

  @spec push(APNS.PushMessage.t, Keyword.t, ((APNS.PushMessage.t, any()) -> any()) | nil) :: {:noreply, map()}
  def push(push_message, opts \\ [], callback_fun \\ nil) do
    # TODO: if SSL congiguration setting were provided via options:
    # * stop active clients that hold current connections (established wuth old settings)
    # * start new clients with SSL configuration from the options
    # * send push message
    # else:
    # * send push message
    if opts[:mode] || opts[:cert] || opts[:key] do
      # TODO: make it work. Now just send push message.
      # stop_and_push(push_message, opts, callback_fun)
      do_push(push_message, opts, callback_fun)
    else
      do_push(push_message, opts, callback_fun)
    end
  end

  @spec stop_and_push(APNS.PushMessage.t, Keyword.t, fun()) :: {:noreply, map()}
  defp stop_and_push(push_message, opts, callback_fun) do
    # TODO: get a client from poolboy, ask it for SSL configuration
    # compare whether SSL config contains same settings, if so - send push message,
    # otherwise: kill all current clients from poolboy, start new and send push message
    opts_map = Enum.into(opts, %{})

    :poolboy.transaction(pool_name(), fn(client) ->
      client_ssl_config = APNS.Client.current_ssl_config(client)
      unless opts_equal?(opts_map, client_ssl_config) do
        # TODO: somehow restart clients in poolboy
      end
    end)

    do_push(push_message, opts, callback_fun)
  end

  @spec do_push(APNS.PushMessage.t, Keyword.t, fun()) :: {:noreply, map()}
  defp do_push(push_message, opts, callback_fun) do
    :poolboy.transaction(pool_name(), fn(client) ->
      APNS.Client.push(client, push_message, opts, callback_fun)
    end)
  end

  @spec pool_name() :: atom()
  defp pool_name, do: Express.Application.apns_pool_name()

  @spec opts_equal?(map(), APNS.SSLConfig.t) :: boolean()
  defp opts_equal?(%{mode: mode}, %{mode: config_mode}), do: mode == config_mode
  defp opts_equal?(%{cert: cert}, %{cert: config_cert}), do: cert == config_cert
  defp opts_equal?(%{key: key}, %{key: config_key}),     do: key  == config_key
end
