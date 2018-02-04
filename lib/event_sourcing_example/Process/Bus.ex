defmodule EventSourcingExample.Bus do
  use GenServer

  alias EventSourcingExample.EventResolver
  alias EventSourcingExample.EventLogger
  alias EventSourcingExample.Mail

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def forward_event(event, opts \\ []) do
    GenServer.call(__MODULE__, {:forward_event, event, opts})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, :state_doesnt_matter}
  end

  defp run_event(event, opts) do
    with {:ok, event_result} <- EventResolver.resolve(event) do
      if (Enum.member?(opts, :do_not_log) == false) do
        EventLogger.save_event(event_result)
      end

      if (Enum.member?(opts, :do_not_send_email) == false) do
        Mail.send_email_if_need(event_result)
      end

      {:ok, event_result}
    else
      err -> err
    end
  end

  def handle_call({:forward_event, [], _opts}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:forward_event, events, opts}, _from, state) when is_list(events) do
    resolve_result = events
      |> Enum.map(&(
        case run_event(&1, opts) do
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

  def handle_call({:forward_event, event, opts}, _from, state) do
    result = run_event(event, opts)
    {:reply, result, state}
  end
end
