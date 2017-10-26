defmodule Helpers.MapHelperTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Express.Helpers.MapHelper

  test "reduce_keys/2: changes map keys with function" do
    map = %{"2" => 1, "3" => 2, "4" => %{"5" => 4}}

    assert %{"1" => 1, "2" => 2, "3" => %{"5" => 4}} == MapHelper.reduce_keys(map, fn(key) ->
      {i, _} = Integer.parse(key)
      Integer.to_string(i - 1)
    end)
  end

  test "deep_reduce_keys/2: deeply changes map keys with function" do
    map = %{"2" => 1, "3" => 2, "4" => %{"5" => 4}}

    assert %{"1" => 1, "2" => 2, "3" => %{"4" => 4}} == MapHelper.deep_reduce_keys(map, fn(key) ->
      {i, _} = Integer.parse(key)
      Integer.to_string(i - 1)
    end)
  end

  test "stringify_keys/2: stringifies map keys" do
    map = %{a: 1, b: 2, c: %{d: 4}}

    assert %{"a" => 1, "b" => 2, "c" => %{d: 4}} == MapHelper.stringify_keys(map)
  end

  test "deep_stringify_keys/2: deeply stringifies map keys" do
    map = %{a: 1, b: 2, c: %{d: 4}}

    assert %{"a" => 1, "b" => 2, "c" => %{"d" => 4}} == MapHelper.deep_stringify_keys(map)
  end

  test "dasherize_keys/2: dasherizes map keys" do
    map = %{"a_a" => 1, "b_b" => 2, "c_c" => %{"d_d" => 4}}

    assert %{"a-a" => 1, "b-b" => 2, "c-c" => %{"d_d" => 4}} == MapHelper.dasherize_keys(map)
  end

  test "deep_dasherize_keys/2: deeply dasherizes map keys" do
    map = %{"a_a" => 1, "b_b" => 2, "c_c" => %{"d_d" => 4}}

    assert %{"a-a" => 1, "b-b" => 2, "c-c" => %{"d-d" => 4}} == MapHelper.deep_dasherize_keys(map)
  end

  test "underscorize_keys/2: underscorizes map keys" do
    map = %{"a-a" => 1, "b-b" => 2, "c-c" => %{"d-d" => 4}}

    assert %{"a_a" => 1, "b_b" => 2, "c_c" => %{"d-d" => 4}} == MapHelper.underscorize_keys(map)
  end

  test "deep_underscorize_keys/2: deeply underscorizes map keys" do
    map = %{"a-a" => 1, "b-b" => 2, "c-c" => %{"d-d" => 4}}

    assert %{"a_a" => 1, "b_b" => 2, "c_c" => %{"d_d" => 4}} == MapHelper.deep_underscorize_keys(map)
  end
end
