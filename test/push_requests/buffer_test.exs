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

  test "start_consumer/0: starts a consumer", %{consumers_sup: consumers_sup} do
    ConsumersSupervisor.start_consumer()
    assert %{active: 1} = Supervisor.count_children(consumers_sup)
  end

  test "any_consumer?/0: checks wether there is a consumer" do
    refute ConsumersSupervisor.any_consumer?()
    ConsumersSupervisor.start_consumer()
    assert ConsumersSupervisor.any_consumer?()
  end
end
