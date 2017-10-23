defmodule Express.FCM.Worker do
  @moduledoc """
  Incapsulates work with FCM logic. Exists temporary: until work with FCM finished.
  """

  use GenServer

  alias Express.FCM.PushMessage
  alias Express.Operations.FCM.Push

  defmodule State do
    @moduledoc """
    Specifies FCM worker state structure.
    """

    @type t :: %__MODULE__{
      push_message: PushMessage.t,
      callback_fun: Express.callback_fun,
      delayed: boolean()
    }

    defstruct ~w(push_message callback_fun delayed)a
  end

  def start_link, do: start_link(:ok)
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok)

  def init(:ok), do: {:ok, %State{}}

  @doc """
  Pushes a `push_message` via `worker` with specified `opts` and `callback_fun`.
  """
  @spec push(module(), PushMessage.t, Keyword.t, Express.callback_fun) :: reference() |
                                                                          :ok |
                                                                          :noconnect |
                                                                          :nosuspend |
                                                                          true
  def push(worker, push_message, opts, callback_fun) do
    Process.send(worker, {:push, push_message, opts, callback_fun}, [])
  end

  @doc """
  Pushes a `push_message` via `worker` with specified `opts` and `callback_fun`
  after a delay specified in the `opts`.
  """
  @spec push_after(module(), PushMessage.t, Keyword.t, Express.callback_fun) :: reference() |
                                                                                :ok |
                                                                                :noconnect |
                                                                                :nosuspend |
                                                                                true
  def push_after(worker, push_message, opts, callback_fun) do
    delay = (opts[:delay] || 1) * 1000
    Process.send_after(worker, {:push, push_message, opts, callback_fun}, delay)
  end

  def handle_info({:push, push_message, opts, callback_fun}, state) do
    Push.run!(
      push_message: push_message,
      opts: opts,
      callback_fun: callback_fun
    )

    new_state =
      state
      |> Map.put(:push_message, push_message)
      |> Map.put(:callback_fun, callback_fun)
      |> Map.put(:delayed, (opts[:delay] && opts[:delay] > 0))

    if new_state.delayed do
      {:stop, :normal, new_state}
    else
      {:noreply, new_state}
    end
  end
end
