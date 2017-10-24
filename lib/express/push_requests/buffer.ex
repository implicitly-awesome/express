defmodule Express.PushRequests.Buffer do
  use GenStage

  alias Express.PushRequests.{PushRequest, ConsumersSupervisor}

  @max_buffer_size 5000

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    send(self(), :init)

    {:producer, [], buffer_size: @max_buffer_size}
  end

  def handle_info(:init, state) do
    consumers_count =
      Application.get_env(:express, :buffer)[:consumers_count] || 5

    Enum.each(1..consumers_count, fn(_) ->
      ConsumersSupervisor.start_consumer()
    end)

    {:noreply, [], state}
  end

  @spec add(PushRequest.t) :: :ok | {:error, any()}
  def add(push_request), do: GenServer.cast(__MODULE__, {:add, push_request})

  def handle_cast({:add, push_request}, state) do
    state = [push_request | state]

    {:noreply, [], state}
  end

  def handle_demand(demand, state) when demand > 0 do
    {push_requests, rest} = Enum.split(state, demand)

    {:noreply, [push_requests], rest}
  end
end
