defmodule Express.APNS.Supervisor do
  @moduledoc """
  APNS supervisor which owns a connection, spawns workers and sends push messages via workers.
  """

  use Supervisor

  alias Express.APNS.{Worker, PushMessage}
  alias Express.Operations.LogMessage

  def start_link(connection) do
    Supervisor.start_link(__MODULE__, {:ok, connection})
  end

  def init({:ok, connection}) do
    children = [
      worker(Worker, [connection], restart: :temporary)
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
        [APNS supervisor] Failed to start worker.
        Reason: #{inspect(reason)}
        State: #{inspect(worker_state)}
        """
        LogMessage.run!(message: error_message)
    end
  end
end
