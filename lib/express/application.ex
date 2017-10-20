defmodule Express.Application do
  @moduledoc "Sets up Express's supervision tree."

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [supervisor(Express.Supervisor, [], restart: :permanent)]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
