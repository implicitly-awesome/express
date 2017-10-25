defmodule PushRequests.BufferTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Express.PushRequests.Buffer
  alias Express.PushRequests.ConsumersSupervisor

  setup do
    {:ok, consumers_sup} = ConsumersSupervisor.start_link()
    {:ok, _buffer} = Buffer.start_link()
    :timer.sleep(100) # dirty hack - need to wait until supervisor starts all children

    {:ok, %{consumers_sup: consumers_sup}}
  end

  test "starts N consumers", %{consumers_sup: consumers_sup} do
    assert %{active: 10} = Supervisor.count_children(consumers_sup)
  end
end
