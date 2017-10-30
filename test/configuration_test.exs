defmodule ConfigurationTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Express.Configuration

  test "gets configuration from config module" do
    assert Configuration.Buffer.consumers_count() == Express.Configuration.Test.buffer()[:consumers_count]
  end

  test "configuration from config file has a priority over config module" do
    assert Configuration.Buffer.max_size() != Express.Configuration.Test.buffer()[:max_size]
    assert Configuration.Buffer.max_size() == Application.get_env(:express, :buffer)[:max_size]
  end
end
