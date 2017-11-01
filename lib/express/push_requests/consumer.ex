defmodule Express.PushRequests.Consumer do
  @moduledoc """
  GenStage consumer.
  Retrieves push requests from `Express.PushRequests.Buffer`,
  gets a proper worker from one of poolboy pools and sends a push message via it.

  Maximum demand (size of a bunch) depends on the number of schedulers available
  for BEAM VM on the current machine: `System.schedulers_online() * 5`

  The default multiplier (5) can be adjusted via config:

      config :express,
        buffer: [
          consumer_demand_multiplier: 10
        ]
  """

  use GenStage

  alias Express.Configuration
  alias Express.APNS.PushMessage, as: APNSPushMessage
  alias Express.FCM.PushMessage, as: FCMPushMessage
  alias Express.APNS.Worker, as: APNSWorker
  alias Express.FCM.Worker, as: FCMWorker
  alias Express.Operations.PoolboyConfigs
  alias Express.PushRequests.PushRequest

  require Logger

  defmodule State do
    @moduledoc "Represents state structure of `Express.PushRequests.Consumer`"

    @type t :: %__MODULE__{producer: pid() | atom(),
                           subscription: pid() | atom()}

    defstruct ~w(producer subscription)a
  end

  def start_link, do: start_link([])
  def start_link(_), do: GenStage.start_link(__MODULE__, :ok)

  def init(:ok) do
    state = %State{producer: Express.PushRequests.Buffer}
    Process.flag(:trap_exit, true)
    send(self(), :init)

    {:consumer, state}
  end

  def handle_info(:init, state) do
    GenStage.async_subscribe(self(), to: state.producer)

    {:noreply, [], state}
  end

  def handle_info({:EXIT, _from, _reason}, state) do
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

  @spec handle_push_requests([PushRequest.t], {pid(), any()}, State.t) :: :ok |
                                                                          :noconnect |
                                                                          :nosuspend
  defp handle_push_requests(push_requests, from, state)
       when is_list(push_requests) and length(push_requests) > 0 do
    push_results =
      push_requests
      |> Task.async_stream(fn(pr) -> do_push(pr, state) end)
      |> Enum.into([])

    killed_workers = killed_workers(push_results)
    if Enum.count(killed_workers) > 0 do
      failed_push_requests =
        Enum.map(killed_workers, fn({_, {_, _, push_request}}) ->
          push_request
        end)

      handle_push_requests(failed_push_requests, from, state)
    else
      ask_more(state)
    end
  end
  defp handle_push_requests(_push_requests, _from, state) do
    ask_more(state)
  end

  @spec do_push(PushRequest.t, State.t) :: any()
  defp do_push(%{push_message: %APNSPushMessage{} = push_message,
                 opts: opts, callback_fun: callback_fun} = push_request, _state) do
    worker = :poolboy.checkout(PoolboyConfigs.apns_workers().name)

    if APNSWorker.connection_alive?(worker) do
      APNSWorker.push(worker, push_message, opts, callback_fun)
      :poolboy.checkin(PoolboyConfigs.apns_workers().name, worker)
    else
      :poolboy.checkin(PoolboyConfigs.apns_workers().name, worker)
      APNSWorker.stop(worker)
      {:error, :worker_killed, push_request}
    end
  end
  defp do_push(%{push_message: %FCMPushMessage{} = push_message,
                 opts: opts, callback_fun: callback_fun}, _state) do
    :poolboy.transaction(PoolboyConfigs.fcm_workers().name, fn(worker) ->
      FCMWorker.push(worker, push_message, opts, callback_fun)
    end)
  end
  defp do_push(_push_request, _state), do: {:error, :unknown_push_message_type}

  @spec killed_workers([Keyword.t]) :: [Keyword.t]
  defp killed_workers(push_results) do
    Enum.filter(push_results, fn({_, v}) ->
      is_tuple(v) && elem(v, 1) == :worker_killed
    end)
  end

  @spec ask_more(State.t) :: :ok |
                             :noconnect |
                             :nosuspend
  defp ask_more(state) do
    GenStage.ask(
      state.subscription,
      System.schedulers_online() * (Configuration.Buffer.consumer_demand_multiplier() || 5)
    )
  end
end
