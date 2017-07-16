defmodule Express.Network.HTTP2.Client do
  @moduledoc """
  HTTP2-clients behaviour.
  """
  @type t :: __MODULE__

  @doc """
  Returns URI of a connection
  """
  @callback uri(atom(), atom()) :: list()

  @doc """
  Открывает сокет для указанного провайдера, конфигурации и количества попыток.
  Establishes 
  """
  @callback open_socket(atom(), map(), pos_integer()) :: {:ok, pid()} |
                                                         {:error, :open_socket, :timeout} |
                                                         {:error, :ssl_config, :certificate_missed} |
                                                         {:error, :ssl_config, :rsa_key_missed}

  @doc """
  Посылает запрос по сокету с заголовками и payload.
  """
  @callback send_request(pid(), list(), String.t) :: {:ok, pid()} | any()

  @doc """
  Получает ответ от сокета для stream.
  """
  @callback get_response(pid(), pid()) :: {:ok, {String.t, String.t}} | any()
end
