defmodule Express.APNS.Supervisor do
  @moduledoc """
  APNS supervisor which owns a connection, spawns workers and sends push messages via workers.
  """

  use Supervisor

  alias Express.APNS.PushMessage
  alias Express.Operations.{LogMessage, APNS.Push}

  def start_link([connection, worker_module]) do
    Supervisor.start_link(__MODULE__, {:ok, connection, worker_module})
  end

  def init({:ok, connection, worker_module}) do
    children = [
      worker(worker_module, [connection], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  @doc """
  Sends `push_message` with the `supervisor`.
  Invokes `callback_fun` function after a response.
  """
  @spec push(pid(), module(), PushMessage.t, Keyword.t | nil,
             Express.callback_fun | nil) :: {:noreply, map()}
  def push(supervisor, worker_module, push_message, opts, callback_fun) do
    worker_state =
      Module.
      concat([worker_module, State]).
      new(push_operation: Push,
          push_message: push_message,
          opts: opts,
          callback_fun: callback_fun)

    delay = opts[:delay] || 0

    case Supervisor.start_child(supervisor, [worker_state]) do
      {:ok, worker} ->
        worker_module.push(worker, delay)
      {:error, reason} ->
        error_message = """
        [APNS supervisor] Failed to start worker.
        Reason: #{inspect(reason)}
        State: #{inspect(worker_state)}
        """
        LogMessage.run!(message: error_message)
    end
  end
end
