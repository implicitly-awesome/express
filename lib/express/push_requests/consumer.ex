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
    GenStage.async_subscribe(self(), to: state.producer, cancel: :temporary)

    {:consumer, state}
  end

  def handle_info(_, state), do: {:stop, :normal, state}

  def handle_subscribe(:producer, _opts, from, state) do
    state = Map.put(state, :subscription, from)

    {:automatic, state}
  end

  def handle_events(push_requests, _from, state) do
    handle_push_requests(push_requests, state)

    {:noreply, [], state}
  end

  def terminate(_reason, _state), do: :normal

  @spec handle_push_requests([PushRequest.t], State.t) :: :ok |
                                                          :noconnect |
                                                          :nosuspend
  defp handle_push_requests([nil], _state), do: :nothing
  defp handle_push_requests(push_requests, state)
       when is_list(push_requests) and length(push_requests) > 0 do
    results =
      Express.TasksSupervisor
      |> Task.Supervisor.async_stream_nolink(push_requests, fn(pr) ->
           do_push(pr, state)
         end
      )
      |> Enum.into([])

    errored_push_requests =
      results
      |> Enum.filter(fn({_, v}) -> is_tuple(v) && elem(v, 0) == :error end)
      |> Enum.map(fn
           {_, {:error, %PushRequest{} = push_request}} -> push_request
           {_, {:error, _}} -> nil
         end)
      |> Enum.reject(&(is_nil(&1)))

    if Enum.any?(errored_push_requests) do
      handle_push_requests(errored_push_requests, state)
    end
  end
  defp handle_push_requests(_push_requests, _state), do: :nothing

  @spec do_push(PushRequest.t, State.t) :: any()
  defp do_push(%{push_message: %APNSPushMessage{} = push_message,
                 opts: opts, callback_fun: callback_fun} = push_request, _state) do
    :poolboy.transaction(PoolboyConfigs.apns_workers().name, fn(worker) ->
      case APNSWorker.push(worker, push_message, opts, callback_fun) do
        {:error, _reason} -> {:error, push_request}
        _ -> :pushed
      end
    end)
  end
  defp do_push(%{push_message: %FCMPushMessage{} = push_message,
                 opts: opts, callback_fun: callback_fun}, _state) do
    :poolboy.transaction(PoolboyConfigs.fcm_workers().name, fn(worker) ->
      FCMWorker.push(worker, push_message, opts, callback_fun)
    end)
  end
  defp do_push(_push_request, _state), do: {:error, :unknown_push_message_type}
end
