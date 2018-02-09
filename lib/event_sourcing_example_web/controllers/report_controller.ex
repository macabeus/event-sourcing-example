defmodule EventSourcingExampleWeb.ReportController do
  use Amnesia
  use EventSourcingExampleWeb, :controller
  use Timex

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

  def inactive_users(conn, _params) do
    users_list =
      Amnesia.transaction(&Database.Account.all/0)
      |> Enum.map(&(&1.account_number))
      |> MapSet.new

    users_transactions =
      Transactions.search(fn(timestamp) ->
        Timex.after?(timestamp, Timex.shift(Timex.today, months: -1))
      end)
      |> Enum.reduce([], &(case &1 do
        %MoneyTransfer{from_account_number: from_account_number, to_account_number: to_account_number} ->
          [[from_account_number, to_account_number] | &2]

        %Withdraw{account_number: account_number} ->
          [account_number | &2]

        _ ->
          &2
      end))
      |> List.flatten
      |> MapSet.new

    inactives = MapSet.difference(users_list, users_transactions)

    json conn, %{total: MapSet.size(inactives)}
  end
end
