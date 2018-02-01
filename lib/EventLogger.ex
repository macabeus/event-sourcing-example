defmodule EventSourcingExample.EventLogger do
  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def save_event(event) do
    GenServer.call(__MODULE__, {:save_event, event})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, table} = :dets.open_file(:events_log, [type: :set])
    :dets.insert_new(table, {"counter", 0})

    [{"counter", counter}] = :dets.lookup(table, "counter")

    {:ok, {table, counter}}
  end

  def handle_call({:save_event, event}, _from, {table, counter}) do
    :dets.insert_new(table, {counter, event})
    :dets.update_counter(table, "counter", 1)

    {:reply, :ok, {table, counter + 1}}
  end
end
