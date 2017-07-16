defmodule Express.APNS.Supervisor do
  @moduledoc """
  APNS supervisor which owns a connection, spawns workers and sends push messages via workers.
  """

  use GenServer
  alias Express.Operations.LogMessage

  alias Express.Network.HTTP2
  alias Express.APNS.{Worker, PushMessage}

  defmodule State do
    @moduledoc """
    Defines APNS supervisor state structure.
    """

    @type t :: %__MODULE__{connection: HTTP2.Connection.t,
                           workers: map(),
                           monitors: pid()}

    defstruct ~w(connection workers monitors)a
  end

  @type open_socket_result :: {:ok, State.t} |
                              {:stop, {:error, :timeout}} |
                              {:stop, {:error, :invalid_ssl_config}} |
                              {:stop, {:error, :unhandled}}

  @spec start_link({HTTP2.Client.t, HTTP2.SSLConfig.t}) :: {:ok, pid} |
                                                           :ignore |
                                                           {:error, {:already_started, pid} | any()}
  def start_link({http2_client, ssl_config}) do
    GenServer.start_link(__MODULE__, {:ok, http2_client, ssl_config})
  end

  @spec init({:ok, HTTP2.Client.t, HTTP2.SSLConfig.t}) :: open_socket_result
  def init({:ok, http2_client, ssl_config}) do
    case HTTP2.connect(http2_client, :apns, ssl_config) do
      {:ok, connection} ->
        {:ok, %State{
          connection: connection,
          workers: %{},
          monitors: :ets.new(:monitors, [:private])
        }}
      {:error, :open_socket, :timeout} ->
        error_message = """
        [APNS supervisor] Could not establish a connection with APNS.
        Is certificate valid and signed for :#{inspect(ssl_config[:mode])} mode? 
        """
        LogMessage.run!(message: error_message)

        {:stop, {:error, :timeout}}
      {:error, :ssl_config, reason} ->
        error_message = """
        [APNS supervisor] Could not establish a connection with APNS.
        Invalid SSL configuration: #{inspect(reason)}
        """
        LogMessage.run!(message: error_message)

        {:stop, {:error, :invalid_ssl_config}}
      _ ->
        error_message = """
        [APNS supervisor] Could not establish a connection with APNS.
        Unhandled error occured.
        """
        LogMessage.run!(message: error_message)

        {:stop, {:error, :unhandled}}
    end
  end

  @doc "Returns SSL configuration with which the connection was established"
  @spec current_ssl_config(pid()) :: HTTP2.SSLConfig.t
  def current_ssl_config(client) do
    :sys.get_state(client).connection.ssl_config
  end

  @doc "Stops the client"
  def stop(client), do: GenServer.stop(client)

  @doc "Returns workers count, which were started by the client"
  def workers_count(client), do: GenServer.call(client, :workers_count)

  @doc "Returns workers description, which were started by the client"
  def workers_list(client), do: GenServer.call(client, :workers_list)

  @doc "Stops a worker"
  def terminate_worker(client, worker_pid) do
    GenServer.call(client, {:terminate_worker, worker_pid})
  end

  @doc """
  Sends `push_message` with the `supervisor`.
  Invokes `callback_fun` function after a response.
  """
  @spec push(pid(), PushMessage.t, Keyword.t | nil,
             ((PushMessage.t, Express.push_result) -> any()) | nil) :: {:noreply, map()}
  def push(client, push_message, opts, callback_fun) do
    GenServer.cast(client, {:push, push_message, opts, callback_fun})
  end

  def handle_call(:workers_count, _from, state) do
    {:reply, Enum.count(state.workers), state}
  end

  def handle_call(:workers_list, _from, state) do
    {:reply, state.workers, state}
  end

  def handle_call({:terminate_worker, worker_pid}, _from, %{monitors: monitors_pid} = state) do
    new_state = if result = demonitor_worker(monitors_pid, worker_pid) do
      new_workers_map = Map.delete(state.workers, worker_pid)
      %{state | workers: new_workers_map}
    else
      state
    end

    {:reply, result, new_state}
  end

  def handle_cast({:push, push_message, opts, callback_fun},
                  %{connection: connection, monitors: monitors_pid} = state) do
    worker_state = %Worker.State{
      connection: connection,
      push_message: push_message,
      opts: opts,
      callback_fun: callback_fun
    }

    worker_pid = spawn_worker(monitors_pid, worker_state)
    new_workers_map = Map.put(state.workers, worker_pid, worker_state)
    new_state = %{state | workers: new_workers_map}

    Worker.push(worker_pid, opts[:delay] || 0)

    {:noreply, new_state}
  end

  def handle_info({:DOWN, _, _, worker_pid, :normal}, %{monitors: monitors_pid} = state) do
    demonitor_worker(monitors_pid, worker_pid)
    {:noreply, state}
  end
  def handle_info({:DOWN, _, _, worker_pid, reason}, %{monitors: monitors_pid} = state) do
    error_message = """
    [APNS supervisor] worker #{inspect(worker_pid)} is down: #{inspect(reason)}
    """
    LogMessage.run!(message: error_message)

    demonitor_worker(monitors_pid, worker_pid)
    {:noreply, state}
  end

  @spec spawn_worker(pid(), Worker.State.t) :: pid()
  defp spawn_worker(monitors_pid, worker_state) do
    {:ok, worker_pid} = Worker.start_link(worker_state)

    ref = Process.monitor(worker_pid)
    true = :ets.insert(monitors_pid, {worker_pid, ref})

    worker_pid
  end

  @spec demonitor_worker(pid(), pid()) :: boolean()
  defp demonitor_worker(monitors_pid, worker_pid) do
    case :ets.lookup(monitors_pid, worker_pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors_pid, pid)
      _ ->
        error_message = """
        [APNS supervisor] Could not remove worker from ETS.
        ref: #{inspect(worker_pid)} 
        """
        LogMessage.run!(message: error_message)

        false
    end
  end
end
