defmodule EventSourcingExample.EventResolver do
  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def resolve(event) do
    GenServer.call(__MODULE__, {:resolve_event, event})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, :state_doesnt_matter}
  end

  def handle_call({:resolve_event, event}, from, state) do
    with {:ok, event_result} <- EventSourcingExample.Event.run(event) do
      GenServer.reply(from, :ok)
      EventSourcingExample.EventLogger.save_event(event_result)

      {:noreply, state}
    else
      err ->
        {:reply, err, state}
    end
  end
end
