defmodule APNS.SupervisorTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Express.APNS

  defmodule FakeWorker do
    @moduledoc false

    defmodule State do
      @moduledoc false

      defstruct ~w(push_operation connection push_message opts callback_fun)a

      def new(args) do
        %__MODULE__{
          push_operation: Keyword.get(args, :push_operation),
          connection: Keyword.get(args, :connection),
          push_message: Keyword.get(args, :push_message),
          opts: Keyword.get(args, :opts),
          callback_fun: Keyword.get(args, :callback_fun)
        }
      end
    end

    def start_link(connection, state) do
      state = %State{state | connection: connection}
      GenServer.start_link(__MODULE__, {:ok, state})
    end

    def init({:ok, state}), do: {:ok, state}

    def push(worker, delay), do: {worker, delay}
  end

  test "init/1: do not spawn workers" do
    {:ok, supervisor} = APNS.Supervisor.start_link([nil, FakeWorker])
    assert %{active: 0, specs: 1, supervisors: 0, workers: 0} ==
           Supervisor.count_children(supervisor)
  end

  test "push/5: spawns a worker and pushes message with it" do
    {:ok, supervisor} = APNS.Supervisor.start_link([nil, FakeWorker])

    result =
      APNS.Supervisor.push(
        supervisor,
        FakeWorker,
        %APNS.PushMessage{},
        [delay: 1],
        fn(_, _) -> :works end
      )

    assert is_tuple(result)

    {worker_pid, 1} = result
    assert is_pid(worker_pid)
  end
end
