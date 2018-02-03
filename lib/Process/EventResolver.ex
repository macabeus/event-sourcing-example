defmodule EventSourcingExample.EventResolver do
  use GenServer

  alias EventSourcingExample.Event

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

  def handle_call({:resolve_many_events, []}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:resolve_event, event}, _from, state) do
    event_result = Event.run(event)
    {:reply, event_result, state}
  end
end
