defmodule Express.FCM.Worker do
  use GenServer

  alias Express.Operations.FCM.Push

  def start_link, do: start_link(:ok)
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok)

  def init(:ok), do: {:ok, %{}}

  def push(worker, push_message, opts, callback_fun) do
    GenServer.cast(worker, {:push, push_message, opts, callback_fun})
  end

  def handle_cast({:push, push_message, opts, callback_fun}, state) do
    Push.run!(
      push_message: push_message,
      opts: opts,
      callback_fun: callback_fun
    )

    {:noreply, state}
  end
end
