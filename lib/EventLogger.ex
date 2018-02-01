defmodule EventSourcingExample.EventLogger do
  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def save_event(event) do
    GenServer.call(__MODULE__, {:save_event, event})
  end

  def view_logs() do
    :ets.new(:events_log_ets, [:set, :protected, :named_table])
    :dets.to_ets(:events_log, :events_log_ets)

    :observer.start

    IO.puts IO.ANSI.format([
      :green, :bright, "Observer started.\n",
      :black, :normal, "Go to the ", :blue, "\"Table Viewer\"", :black, " and double-click on ", :blue, "\"events_log_ets\"", :black, " to seen the content.\n",
      "When you close the Observer, remember to use ", :blue, "\":ets.delete(:events_log_ets)\"", :black, " command."
    ])
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
