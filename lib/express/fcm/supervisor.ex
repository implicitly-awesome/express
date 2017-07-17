defmodule Express.FCM.Supervisor do
  @moduledoc """
  FCM supervisor which spawns workers and sends push messages via workers.
  """

  use Supervisor

  alias Express.FCM.{Worker, PushMessage}
  alias Express.Operations.LogMessage

  def start_link([]), do: Supervisor.start_link(__MODULE__, :ok)

  def init(:ok) do
    children = [
      worker(Worker, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  @doc """
  Sends `push_message` with the `supervisor`.
  Invokes `callback_fun` function after a response.
  """
  @spec push(pid(), PushMessage.t, Keyword.t | nil,
             Express.callback_fun | nil) :: {:noreply, map()}
  def push(supervisor, push_message, opts, callback_fun) do
    worker_state =
      %Worker.State{
        push_message: push_message,
        opts: opts,
        callback_fun: callback_fun
      }

    delay = opts[:delay] || 0

    case Supervisor.start_child(supervisor, [worker_state]) do
      {:ok, worker} ->
        Worker.push(worker, delay)
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
