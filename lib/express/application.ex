defmodule Express.Application do
  @moduledoc "The application. Starts the main supervisor."

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [supervisor(Express.Supervisor, [], restart: :permanent)]

    if Mix.env() == :test do
      Supervisor.start_link([], strategy: :one_for_one)
    else
      Supervisor.start_link(children, strategy: :one_for_one)
    end
  end
end
