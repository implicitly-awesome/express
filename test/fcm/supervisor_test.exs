defmodule FCM.SupervisorTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Express.FCM

  defmodule FakeWorker do
    @moduledoc false

    defmodule State do
      @moduledoc false

      defstruct ~w(push_message opts callback_fun)a

      def new(args) do
        %__MODULE__{
          push_message: Keyword.get(args, :push_message),
          opts: Keyword.get(args, :opts),
          callback_fun: Keyword.get(args, :callback_fun)
        }
      end
    end

    def start_link(state), do: GenServer.start_link(__MODULE__, {:ok, state})

    def init({:ok, state}), do: {:ok, state}

    def push(worker, delay), do: {worker, delay}
  end

  test "init/1: do not spawn workers" do
    {:ok, supervisor} = FCM.Supervisor.start_link(FakeWorker)
    assert %{active: 0, specs: 1, supervisors: 0, workers: 0} ==
           Supervisor.count_children(supervisor)
  end

  test "push/5: spawns a worker and pushes message with it" do
    {:ok, supervisor} = FCM.Supervisor.start_link(FakeWorker)

    result =
      FCM.Supervisor.push(
        supervisor,
        FakeWorker,
        %FCM.PushMessage{},
        [],
        fn(_, _) -> :works end
      )

    assert is_tuple(result)
    {worker_pid, 0} = result
    assert is_pid(worker_pid)
  end
end
