defmodule Express.PushRequests.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok), do: supervise(children(), opts())

  defp children do
    [
      supervisor(
        Express.PushRequests.ConsumersSupervisor,
        [],
        restart: :permanent
      ),
      worker(
        Express.PushRequests.Buffer,
        [],
        restart: :permanent,
        name: Express.PushRequests.Buffer
      ),
      :poolboy.child_spec(
        buffer_adders_pool_name(),
        buffer_adders_poolboy_config(),
        []
      )
    ]
  end

  defp opts do
    [
      strategy: :one_for_one,
      name: __MODULE__
    ]
  end

  @spec buffer_adders_poolboy_config() :: Keyword.t
  def buffer_adders_poolboy_config do
    Application.get_env(:express, :buffer)[:adders_poolboy_config] ||
    [
      {:name, {:local, :buffer_adders_pool}},
      {:worker_module, Express.PushRequests.Adder},
      {:size, 5},
      {:max_overflow, 1}
    ]
  end

  @spec buffer_adders_pool_name() :: atom()
  def buffer_adders_pool_name do
    [{:name, {_, name}} | _] = buffer_adders_poolboy_config()
    name
  end

  @spec buffer_consumers_poolboy_config() :: Keyword.t
  def buffer_consumers_poolboy_config do
    Application.get_env(:express, :buffer)[:consumers_poolboy_config] ||
    [
      {:name, {:local, :buffer_consumers_pool}},
      {:worker_module, Express.PushRequests.Consumer},
      {:size, 5},
      {:max_overflow, 1}
    ]
  end

  @spec buffer_consumers_pool_name() :: atom()
  def buffer_consumers_pool_name do
    [{:name, {_, name}} | _] = buffer_consumers_poolboy_config()
    name
  end
end
