defmodule APNS.JWTHolderTest do
  @moduledoc false

  alias Express.APNS.JWTHolder

  import Joken
  import Mock

  use ExUnit.Case, async: false

  setup do
    {:ok, _} = JWTHolder.start_link()
    jwt = JWTHolder.get_jwt()

    {:ok, %{jwt: jwt}}
  end

  test "creates a new valid jwt after a start", %{jwt: jwt} do
    jwt =
      jwt
      |> token()
      |> with_signer(es256(JWTHolder.apns_auth_key()))
      |> verify()

    assert (jwt.claims |> Map.keys() |> Enum.any?())
  end

  test "returns the same jwt if it is not expired", %{jwt: jwt} do
    assert jwt == JWTHolder.get_jwt()
  end

  test "creates a new valid jwt if it is expired", %{jwt: jwt} do
    now = Timex.now()

    with_mock Timex, [
      now: fn() -> now end,
      to_unix: fn(_) -> 999_999_999 end,
      diff: fn(_, _, _) -> 999_999_999 end,
    ]
    do
      assert jwt != JWTHolder.get_jwt()
    end
  end
end
