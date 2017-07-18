defmodule FCM.WorkerTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Express.FCM.{Worker, Worker.State, PushMessage}

  defmodule FakePushOperation do
    @moduledoc false

    def run(args), do: args[:callback_fun].(:a, :b)
  end

  setup do
    registration_id = "your_registration_id"
    notification = %PushMessage.Notification{title: "Title", body: "Body"}
    push_message = %PushMessage{
      registration_ids: [registration_id],
      notification: notification,
      data: %{}
    }

    worker_state =
      State.new(
        push_operation: FakePushOperation,
        push_message: push_message,
        opts: [],
        callback_fun: fn(_, _) -> :pushed end
      )

    {:ok, worker_state: worker_state}
  end

  describe "push/2" do
    test "with delay == 0 sends :push immediately", %{
      worker_state: worker_state
    } do
      start_time = :erlang.timestamp

      worker_state = Map.merge(worker_state, %{
        callback_fun: fn(_, _) ->
          # let 'immediately' be less than 1 sec :)
          assert :timer.now_diff(:erlang.timestamp, start_time) < 1_000_000
        end
      })

      {:ok, worker} = Worker.start_link(worker_state)
      ref = Process.monitor(worker)
      delay = 0

      Worker.push(worker, delay)
      assert_receive {:DOWN, ^ref, _, _, _}
      refute Process.alive?(worker)
    end
  end

  describe "push/2" do
    test "with delay > 0 sends :push after that delay", %{
      worker_state: worker_state
    } do
      start_time = :erlang.timestamp

      worker_state = Map.merge(worker_state, %{
        callback_fun: fn(_, _) ->
          assert :timer.now_diff(:erlang.timestamp, start_time) > 1_000_000
        end
      })

      {:ok, worker} = Worker.start_link(worker_state)
      ref = Process.monitor(worker)
      delay = 1

      Worker.push(worker, delay)
      assert_receive {:DOWN, ^ref, _, _, _}, delay * 1000 + 100
      refute Process.alive?(worker)
    end
  end
end
