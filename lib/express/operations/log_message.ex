defmodule Express.Operations.LogMessage do
  @moduledoc """
  Sends a message to the Logger.
  
  [Exop](https://github.com/madeinussr/exop) library operation.

  Takes parameters:
  * `message` (String)
  * `type` of the message (error/warn/info)
  """

  use Exop.Operation

  require Logger

  parameter :message, type: :string,  required: true
  parameter :type,    type: :atom, in: ~w(error warn info)a, default: :error

  def process(contract), do: do_log(contract[:message], contract[:type])

  @spec do_log(String.t, :error | :warn | :info) :: :ok | {:error, any()}
  defp do_log(message, :error), do: Logger.error(message)
  defp do_log(message, :warn), do: Logger.warn(message)
  defp do_log(message, :info), do: Logger.info(message)
end
