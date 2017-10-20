defmodule Express.APNS.DelayedPushes do
  @moduledoc """
  APNS supervisor which spawns workers and sends via them a push message after a delay.
  """

  use Supervisor

  alias Express.APNS.{PushMessage, Worker}
  alias Express.Operations.LogMessage

  def start_link, do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok) do
    children = [worker(Worker, [], restart: :temporary)]

    supervise(children, strategy: :simple_one_for_one)
  end

  @doc """
  Adds a `push_message` to the `supervisor`'s queue.
  The push message will be sent by a worker after delay provided in `opts`.
  Invokes `callback_fun` function after a response.
  """
  @spec add(PushMessage.t, Keyword.t | nil,
            Express.callback_fun | nil) :: {:noreply, map()}
  def add(push_message, opts, callback_fun) do
    case Supervisor.start_child(__MODULE__, []) do
      {:ok, worker} ->
        Worker.push_after(worker, push_message, opts, callback_fun)
      {:error, reason} ->
        error_message = """
        [APNS supervisor] Failed to start worker.
        Reason: #{inspect(reason)}
        """
        LogMessage.run!(message: error_message)
    end
  end
end
