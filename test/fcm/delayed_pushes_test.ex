defmodule FCM.DelayedPushesTest do
  @moduledoc false

  alias Express.FCM.DelayedPushes
  alias Express.FCM.PushMessage

  use ExUnit.Case, async: true

  setup do
    {:ok, sup_pid} = DelayedPushes.start_link()

    {:ok, %{sup_pid: sup_pid}}
  end

  test "add/3: spawns a buffer adder", %{sup_pid: sup_pid} do
    DelayedPushes.add(%PushMessage{}, [delay: 3], fn(_, _) -> :ok end)
    DelayedPushes.add(%PushMessage{}, [delay: 3], fn(_, _) -> :ok end)

    assert %{active: 2} = Supervisor.count_children(sup_pid)
  end
end
