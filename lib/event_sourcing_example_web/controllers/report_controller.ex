defmodule EventSourcingExampleWeb.ReportController do
  use EventSourcingExampleWeb, :controller

  alias EventSourcingExample.EventLog.SearchTransactions, as: Transactions
  alias EventSourcingExample.Event.MoneyTransfer
  alias EventSourcingExample.Event.Withdraw

  def sum_transactions(conn, %{"year" => year, "month" => month, "day" => day}) do
    year  = String.to_integer(year)
    month = String.to_integer(month)
    day   = String.to_integer(day)

    sum = Transactions.search(%{year: year, month: month, day: day})
      |> op_sum_transactions

    json conn, %{sum: sum}
  end

  def sum_transactions(conn, %{"year" => year, "month" => month}) do
    year  = String.to_integer(year)
    month = String.to_integer(month)

    sum = Transactions.search(%{year: year, month: month})
      |> op_sum_transactions

    json conn, %{sum: sum}
  end

  def sum_transactions(conn, %{"year" => year}) do
    year  = String.to_integer(year)

    sum = Transactions.search(%{year: year})
      |> op_sum_transactions

    json conn, %{sum: sum}
  end

  def sum_transactions(conn, %{}) do
    sum = Transactions.search(%{})
      |> op_sum_transactions

    json conn, %{sum: sum}
  end

  defp op_sum_transactions(transactions) do
    Enum.reduce(transactions, 0, &(
      case &1 do
        %MoneyTransfer{amount: amount} -> amount + &2
        %Withdraw{amount: amount}      -> amount + &2
        _                              -> &2
      end)
    )
  end
end
