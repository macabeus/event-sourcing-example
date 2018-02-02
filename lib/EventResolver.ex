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

  def resolve_many(events) do
    GenServer.call(__MODULE__, {:resolve_many_events, events})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, :state_doesnt_matter}
  end

  def handle_call({:resolve_many_events, []}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:resolve_many_events, events}, _from, state) do
    resolve_result =
      events
      |> Enum.map(&(
        case Event.run(&1) do
          {:ok, _} -> :ok
          {:error, message} -> {message, &1}
        end))
      |> Enum.uniq

    with 1   <- length(resolve_result),
         :ok <- List.first(resolve_result)
    do
      {:reply, :ok, state}
    else
      _ ->
        resolve_result = Enum.filter(resolve_result, &(&1 != :ok))
        {:reply, {:error, resolve_result}, state}
    end
  end

  def handle_call({:resolve_event, event}, from, state) do
    with {:ok, event_result} <- Event.run(event) do
      GenServer.reply(from, :ok)
      EventSourcingExample.EventLogger.save_event(event_result)

      {:noreply, state}
    else
      err ->
        {:reply, err, state}
    end
  end
end
