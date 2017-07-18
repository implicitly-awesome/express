defmodule Express.FCM.Supervisor do
  @moduledoc """
  FCM supervisor which spawns workers and sends push messages via workers.
  """

  use Supervisor

  alias Express.FCM.PushMessage
  alias Express.Operations.{LogMessage, FCM.Push}

  def start_link(worker_module) do
    Supervisor.start_link(__MODULE__, {:ok, worker_module})
  end

  def init({:ok, worker_module}) do
    children = [
      worker(worker_module, [], restart: :temporary)
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
        [FCM supervisor] Failed to start worker.
        Reason: #{inspect(reason)}
        State: #{inspect(worker_state)}
        """
        LogMessage.run!(message: error_message)
    end
  end
end
