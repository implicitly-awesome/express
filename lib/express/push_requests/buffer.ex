defmodule Express.PushRequests.Buffer do
  @moduledoc """
  GenStage producer. Acts like a buffer for incoming push messages.
  Default buffer size is 5000 events.
  This size can be adjusted via config file:

      config :express,
            buffer: [
              max_size: 10_000
            ]

  Spawns number of GenStage consumers on init. Default amount of the consumers is 5.
  This amount can be changed in config file:

      config :express,
          buffer: [
            consumers_count: 10
          ]
  """

  use GenStage

  alias Express.Configuration
  alias Express.PushRequests.{PushRequest, ConsumersSupervisor}

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    send(self(), :init)

    {:producer, [], buffer_size: (Configuration.Buffer.max_size() || 5000)}
  end

  def handle_info(:init, state) do
    consumers_count = Configuration.Buffer.consumers_count() || 5

    Enum.each(1..consumers_count, fn(_) ->
      ConsumersSupervisor.start_consumer()
    end)

    {:noreply, [], state}
  end

  @doc "Adds a push request to the buffer."
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
