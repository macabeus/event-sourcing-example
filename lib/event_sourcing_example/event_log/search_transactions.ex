defmodule EventSourcingExample.EventLog.SearchTransactions do
  alias EventSourcingExample.Event.NewAccount
  alias EventSourcingExample.Event.MoneyTransfer
  alias EventSourcingExample.Event.Withdraw

  def search(filter_data_func) when is_function(filter_data_func) do
    :dets.foldl(&(filter_transactions(filter_data_func, &1, &2)), [], :events_log)
  end

  def search(%{year: year, month: month, day: day}) do
    filter_data_func = fn(timestamp) ->
      case {timestamp.year, timestamp.month, timestamp.day} do
        {^year, ^month, ^day} -> true
        _ -> false
      end
    end

    :dets.foldl(&(filter_transactions(filter_data_func, &1, &2)), [], :events_log)
  end

  def search(%{year: year, month: month}) do
    filter_data_func = fn(timestamp) ->
      case {timestamp.year, timestamp.month} do
        {^year, ^month} -> true
        _ -> false
      end
    end

    :dets.foldl(&(filter_transactions(filter_data_func, &1, &2)), [], :events_log)
  end

  def search(%{year: year}) do
    filter_data_func = fn(timestamp) ->
      case timestamp.year do
        ^year -> true
        _ -> false
      end
    end

    :dets.foldl(&(filter_transactions(filter_data_func, &1, &2)), [], :events_log)
  end

  def search(%{}) do
    filter_data_func = fn(_timestamp) ->
      true
    end

    :dets.foldl(&(filter_transactions(filter_data_func, &1, &2)), [], :events_log)
  end

  defp filter_transactions(filter_data_func, {_index, timestamp, event}, acc) do
    if filter_data_func.(timestamp) do
      case event do
        %MoneyTransfer{} ->
          [event | acc]

        %Withdraw{} ->
          [event | acc]

        _ ->
          acc
      end
    else
      acc
    end
  end

  defp filter_transactions(_, _, acc) do
    acc
  end
end
