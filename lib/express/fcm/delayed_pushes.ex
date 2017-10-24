defmodule Express.FCM.DelayedPushes do
  use Supervisor

  alias Express.FCM.PushMessage
  alias Express.Operations.LogMessage
  alias Express.PushRequests.Adder

  def start_link, do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok) do
    children = [worker(Adder, [], restart: :temporary)]

    supervise(children, strategy: :simple_one_for_one)
  end

  @spec add(PushMessage.t, Keyword.t | nil,
            Express.callback_fun | nil) :: {:noreply, map()}
  def add(push_message, opts, callback_fun) do
    case Supervisor.start_child(__MODULE__, []) do
      {:ok, adder} ->
        Adder.add_after(adder, push_message, opts, callback_fun)
      {:error, reason} ->
        error_message = """
        [FCM DelayedPushes] Failed to start an adder.
        Reason: #{inspect(reason)}
        """
        LogMessage.run!(message: error_message)
    end
  end
end
