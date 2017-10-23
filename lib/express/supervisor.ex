defmodule Express.Supervisor do
  @moduledoc "Sets up Express's supervision tree."

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, {:ok, Mix.env()}, name: __MODULE__)
  end

  def init({:ok, :test}), do: supervise([], opts())
  def init({:ok, _}), do: supervise(children(), opts())

  defp children do
    [
      supervisor(Express.APNS.Supervisor, [], restart: :permanent),
      supervisor(Express.FCM.Supervisor, [], restart: :permanent)
    ]
  end

  defp opts do
    [
      strategy: :one_for_one,
      name: Express.Supervisor
    ]
  end
end
