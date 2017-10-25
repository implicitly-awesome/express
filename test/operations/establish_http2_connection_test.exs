defmodule Operations.EstablishHTTP2ConnectionTest do
  @moduledoc false

  use ExUnit.Case, async: false

  import Mock

  alias Express.Network.HTTP2
  alias Express.Network.HTTP2.Connection
  alias Express.Operations.EstablishHTTP2Connection
  alias Express.Network.HTTP2.{ChatterboxClient, SSLConfig}

  describe "when ssl config was provided" do
    test "opens a connection" do
      with_mock HTTP2, [connect: fn(_client, _provider, _ssl_config) -> {:ok, %Connection{}} end] do
        params = [http2_client: ChatterboxClient, ssl_config: %SSLConfig{}]
        assert {:ok, %Connection{} = _conn} = EstablishHTTP2Connection.run(params)
      end
    end

    test "returns an error on timeout" do
      with_mock HTTP2, [connect: fn(_client, _provider, _ssl_config) -> {:error, :open_socket, :timeout} end] do
        params = [http2_client: ChatterboxClient, ssl_config: %SSLConfig{}]
        assert {:error, :timeout} = EstablishHTTP2Connection.run(params)
      end
    end

    test "returns an error with bad ssl config" do
      with_mock HTTP2, [connect: fn(_client, _provider, _ssl_config) -> {:error, :ssl_config, "bad bad"} end] do
        params = [http2_client: ChatterboxClient, ssl_config: %SSLConfig{}]
        assert {:error, :invalid_ssl_config} = EstablishHTTP2Connection.run(params)
      end
    end

    test "returns an unhandled error for other connection result" do
      with_mock HTTP2, [connect: fn(_client, _provider, _ssl_config) -> "unknown result" end] do
        params = [http2_client: ChatterboxClient, ssl_config: %SSLConfig{}]
        assert {:error, :unhandled} = EstablishHTTP2Connection.run(params)
      end
    end
  end

  describe "without ssl config" do
    test "opens a connection" do
      with_mock HTTP2, [connect: fn(_client, _provider) -> {:ok, %Connection{}} end] do
        params = [http2_client: ChatterboxClient]
        assert {:ok, %Connection{} = _conn} = EstablishHTTP2Connection.run(params)
      end
    end

    test "returns an error on timeout" do
      with_mock HTTP2, [connect: fn(_client, _provider) -> {:error, :open_socket, :timeout} end] do
        params = [http2_client: ChatterboxClient]
        assert {:error, :timeout} = EstablishHTTP2Connection.run(params)
      end
    end

    test "returns an unhandled error for other connection result" do
      with_mock HTTP2, [connect: fn(_client, _provider) -> "unknown result" end] do
        params = [http2_client: ChatterboxClient]
        assert {:error, :unhandled} = EstablishHTTP2Connection.run(params)
      end
    end
  end
end
