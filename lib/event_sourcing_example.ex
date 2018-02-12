defmodule EventSourcingExample do
  use Application

  alias EventSourcingExample.Supervisor
  alias EventSourcingExample.EventLogger
  alias EventSourcingExample.Bus
  alias EventSourcingExample.Snapshotter

  def start(_type, _args) do
    {:ok, pid} = Supervisor.start_link([])

    recover_events =
      if recover_previous_state?() do
        Snapshotter.restore_last_snapshot()

        EventLogger.recover_events()
        |> Bus.forward_event([:do_not_log, :do_not_send_email])
      else
        :ok
      end

    case recover_events do
      :ok ->
        {:ok, pid}

      {:error, recover_error} ->
        {:error, {"Some error happened when tried recover the state!", recover_error}}
    end
  end

  def recover_previous_state? do
    Application.get_env(:event_sourcing_example, EventSourcingExample, :recover_previous_state)[:recover_previous_state]
  end
end
