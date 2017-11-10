defmodule Express.Supervisor do
  @moduledoc "Sets up Express's supervision tree."

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok), do: supervise(children(), opts())

  defp children do
    [
      supervisor(Express.APNS.Supervisor, [], restart: :permanent),
      supervisor(Express.FCM.Supervisor, [], restart: :permanent),
      supervisor(Express.PushRequests.Supervisor, [], restart: :permanent),
      supervisor(
        Task.Supervisor,
        [[name: Express.TasksSupervisor, restart: :transient]],
        restart: :permanent
      )
    ]
  end

  defp opts do
    [strategy: :one_for_one, name: __MODULE__]
  end
end
