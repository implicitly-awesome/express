defmodule Express.Network.HTTP2.Client do
  @moduledoc """
  HTTP2-clients behaviour.
  """
  @type t :: __MODULE__

  @doc "Returns URI of a connection"
  @callback uri(atom(), atom()) :: list()

  @doc """
  Opens a socket for a `provider` with defined `configuration` and tries `count`.
  """
  @callback open_socket(atom(), map(), pos_integer()) ::
    {:ok, pid()} |
    {:error, :open_socket, :timeout} |
    {:error, :ssl_config, :certificate_missed} |
    {:error, :ssl_config, :rsa_key_missed}

  @doc """
  Sends a request through a socket by `pid` with `headers` and a `payload`.
  """
  @callback send_request(pid(), list(), String.t) :: {:ok, pid()} | any()

  @doc """
  Receives a response from socket by `pid` for a `stream`.
  """
  @callback get_response(pid(), pid()) :: {:ok, {String.t, String.t}} | any()
end
