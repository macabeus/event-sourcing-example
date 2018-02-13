defmodule EventSourcingExample.EventLogger do
  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def save_event(event) do
    GenServer.call(__MODULE__, {:save_event, event})
  end

  def recover_events() do
    GenServer.call(__MODULE__, :recover_events)
  end

  def update_last_snapshot(new_value) do
    GenServer.call(__MODULE__, {:update_last_snapshot, new_value})
  end

  def view_logs() do
    :ets.new(:events_log_ets, [:set, :protected, :named_table])
    :dets.to_ets(:events_log, :events_log_ets)

    :observer.start()

    IO.puts(
      IO.ANSI.format([
        :green,
        :bright,
        "Observer started.\n",
        :black,
        :normal,
        "Go to the ",
        :blue,
        "\"Table Viewer\"",
        :black,
        " and double-click on ",
        :blue,
        "\"events_log_ets\"",
        :black,
        " to seen the content.\n",
        "When you close the Observer, remember to use ",
        :blue,
        "\":ets.delete(:events_log_ets)\"",
        :black,
        " command."
      ])
    )
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, _} = :dets.open_file(:events_log, type: :set)
    {:ok, _} = :dets.open_file(:meta_logs, type: :set)

    :dets.insert_new(:meta_logs, {"events_counter", 0})
    :dets.insert_new(:meta_logs, {"last_snapshot", 0})

    [{"events_counter", events_counter}] = :dets.lookup(:meta_logs, "events_counter")
    [{"last_snapshot", last_snapshot}] = :dets.lookup(:meta_logs, "last_snapshot")

    {:ok, {events_counter, last_snapshot}}
  end

  def handle_call({:save_event, event}, _from, {events_counter, last_snapshot}) do
    timestamp = DateTime.utc_now()

    :dets.insert_new(:events_log, {events_counter, timestamp, event})
    :dets.update_counter(:meta_logs, "events_counter", 1)

    events_counter = events_counter + 1

    {:reply, {:ok, events_counter}, {events_counter, last_snapshot}}
  end

  def handle_call(:recover_events, _from, {0, _last_snapshot} = state) do
    {:reply, [], state}
  end

  def handle_call(:recover_events, _from, {events_counter, last_snapshot} = state) do
    if last_snapshot > events_counter - 1 do
      {:reply, [], state}
    else
      events =
        last_snapshot..(events_counter - 1)
        |> Enum.map(fn i ->
          [{_index, _timestamp, event}] = :dets.lookup(:events_log, i)
          event
        end)

      {:reply, events, state}
    end
  end

  def handle_call({:update_last_snapshot, new_value}, _from, {events_counter, _last_snapshot}) do
    :dets.insert(:meta_logs, {"last_snapshot", new_value})

    {:reply, :ok, {events_counter, new_value}}
  end
end
