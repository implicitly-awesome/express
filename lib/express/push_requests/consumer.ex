defmodule Express.PushRequests.Consumer do
  use GenStage

  alias Express.APNS.PushMessage, as: APNSPushMessage
  alias Express.FCM.PushMessage, as: FCMPushMessage
  alias Express.APNS.Worker, as: APNSWorker
  alias Express.FCM.Worker, as: FCMWorker
  alias Express.APNS.Supervisor, as: APNSSupervisor
  alias Express.FCM.Supervisor, as: FCMSupervisor

  @max_demand System.schedulers_online() * 10

  defmodule State do
    @type t :: %__MODULE__{producer: pid() | atom(),
                           subscription: pid() | atom()}

    defstruct ~w(producer subscription)a
  end

  def start_link, do: start_link([])
  def start_link(_), do: GenStage.start_link(__MODULE__, :ok)

  def init(:ok) do
    state = %State{producer: Express.PushRequests.Buffer}
    send(self(), :init)

    {:consumer, state}
  end

  def handle_info(:init, state) do
    GenStage.async_subscribe(self(), to: state.producer)

    {:noreply, [], state}
  end

  def handle_subscribe(:producer, _opts, from, state) do
    state = Map.put(state, :subscription, from)
    ask_more(state)

    {:manual, state}
  end

  def handle_events([push_requests], from, state) do
    handle_push_requests(push_requests, from, state)

    {:noreply, [], state}
  end

  defp handle_push_requests(push_requests, _from, state)
       when is_list(push_requests) and length(push_requests) > 0 do
    push_requests
    |> Task.async_stream(fn(pr) -> do_push(pr, state) end)
    |> Enum.into([])

    ask_more(state)
  end
  defp handle_push_requests(_push_requests, _from, state) do
    ask_more(state)
  end

  defp do_push(%{push_message: %APNSPushMessage{} = push_message,
                 opts: opts, callback_fun: callback_fun}, _state) do
    :poolboy.transaction(APNSSupervisor.apns_workers_pool_name(), fn(worker) ->
      APNSWorker.push(worker, push_message, opts, callback_fun)
    end)
  end
  defp do_push(%{push_message: %FCMPushMessage{} = push_message,
                 opts: opts, callback_fun: callback_fun}, _state) do
    :poolboy.transaction(FCMSupervisor.fcm_workers_pool_name(), fn(worker) ->
      FCMWorker.push(worker, push_message, opts, callback_fun)
    end)
  end
  defp do_push(_push_request, _state), do: {:error, :unknown_push_message_type}

  defp ask_more(state) do
    GenStage.ask(state.subscription, @max_demand)
  end
end
