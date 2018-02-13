defmodule EventSourcingExample.Snapshotter do
  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def take_snapshot_if_need(events_counter, _opts \\ []) do
    GenServer.call(__MODULE__, {:take_snapshot_if_need, events_counter})
  end

  def restore_last_snapshot() do
    GenServer.call(__MODULE__, :restore_last_snapshot)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, :state_doesnt_matter}
  end

  defp needs_a_new_snapshot?(events_counter) do
    case rem(events_counter, 5) do
      0 -> true
      _ -> false
    end
  end

  def handle_call({:take_snapshot_if_need, events_counter}, _from, state) do
    case needs_a_new_snapshot?(events_counter) do
      true ->
        Amnesia.Backup.checkpoint(%{
          name: 'snapshot',
          max: [Database.Account, Database.VerifyCode, Database],
          override: true
        })

        Amnesia.Backup.start('snapshot', 'snapshot')

        EventSourcingExample.EventLogger.update_last_snapshot(events_counter)

        {:reply, :ok, state}

      false ->
        {:reply, :ok, state}
    end
  end

  def handle_call(:restore_last_snapshot, _from, state) do
    Amnesia.Backup.restore('snapshot', nil)

    {:reply, :ok, state}
  end
end
