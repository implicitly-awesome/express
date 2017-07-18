defmodule Express.FCM.Worker do
  @moduledoc """
  Incapsulates work with FCM logic. Exists temporary: until work with FCM finished.
  """

  use GenServer

  alias Express.FCM.PushMessage

  defmodule State do
    @moduledoc """
    Specifies FCM worker state structure.
    """

    @type t :: %__MODULE__{
      push_operation: module(),
      push_message: PushMessage.t,
      opts: Keyword.t,
      callback_fun: ((PushMessage.t, any()) -> any()) | nil
    }

    defstruct ~w(push_operation push_message opts callback_fun)a

    @spec new(Keyword.t) :: __MODULE__.t
    def new(args) do
      %__MODULE__{
        push_operation: Keyword.get(args, :push_operation),
        push_message: Keyword.get(args, :push_message),
        opts: Keyword.get(args, :opts),
        callback_fun: Keyword.get(args, :callback_fun)
      }
    end
  end

  @spec start_link(State.t) :: {:ok, pid} |
                               :ignore |
                               {:error, {:already_started, pid} | any()}
  def start_link(state), do: GenServer.start_link(__MODULE__, {:ok, state})

  def init({:ok, state}), do: {:ok, state}

  @doc """
  Pushes a push message via `worker` with specified `delay`.
  """
  @spec push(pid(), pos_integer()) :: reference() |
                                      :ok |
                                      :noconnect |
                                      :nosuspend |
                                      true
  def push(worker, delay \\ 0)
  def push(worker, delay) when is_integer(delay) and delay >= 1 do
    Process.send_after(worker, :push, delay * 1000)
  end
  def push(worker, delay) when is_integer(delay) do
    Process.send(worker, :push, [])
  end
  def push(worker, _delay) do
    Process.exit(worker, :normal)
  end

  def handle_info(:push, %{push_operation: push_operation,
                           push_message: push_message,
                           opts: opts,
                           callback_fun: callback_fun} = state) do
    push_operation.run(
      push_message: push_message,
      opts: opts,
      callback_fun: callback_fun
    )

    {:stop, :normal, state}
  end
end
