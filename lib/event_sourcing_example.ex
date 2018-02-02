defmodule EventSourcingExample do
  use Application

  alias EventSourcingExample.Supervisor
  alias EventSourcingExample.EventResolver
  alias EventSourcingExample.EventLogger

  def start(_type, _args) do
    {:ok, pid} = Supervisor.start_link([])

    # Recover the past state of application
    resolve_result =
      EventLogger.recover_events()
      |> EventResolver.resolve_many()

    case resolve_result do
      :ok ->
        {:ok, pid}

      {:error, recover_error} ->
        {:error, {"Some error happened when tried recover the state!", recover_error}}
    end
  end
end
