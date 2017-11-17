defmodule Express.PushRequests.Adder do
  @moduledoc """
  Responsible for adding a push message to Buffer.
  If was called with opts[:delay] > 0 - stops after job done.
  """

  use GenServer

  alias Express.PushRequests.Buffer
  alias Express.PushRequests.PushRequest
  alias Express.{APNS, FCM}

  def start_link, do: start_link(:ok)
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok)

  def init(:ok), do: {:ok, %{}}

  @doc "Adds a push message to the Buffer"
  @spec add(pid(), APNS.PushMessage | FCM.PushMessage, Keyword.t, Express.callback_fun) :: any()
  def add(adder, push_message, opts, callback_fun) do
    Process.send(adder, {:add, push_message, opts, callback_fun}, [])
  end

  @doc "Adds a push message to the Buffer after a delay provided in `opts`"
  @spec add_after(pid(), APNS.PushMessage | FCM.PushMessage, Keyword.t, Express.callback_fun) :: any()    
  def add_after(adder, push_message, opts, callback_fun) do
    delay = (opts[:delay] || 1) * 1000
    Process.send_after(adder, {:add, push_message, opts, callback_fun}, delay)
  end

  def handle_info({:add, push_message, opts, callback_fun}, state) do
    Buffer.add(%PushRequest{
      push_message: push_message,
      opts: opts,
      callback_fun: callback_fun
    })

    if is_integer(opts[:delay]) && opts[:delay] > 0 do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  def terminate({:timeout, _}, _state) do
    pid = Process.whereis(Express.PushRequests.Buffer)
    Process.exit(pid, :kill)
    :normal
  end
end
