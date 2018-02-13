defmodule EventSourcingExampleWeb.BankingController do
  use EventSourcingExampleWeb, :controller

  alias EventSourcingExample.Bus
  alias EventSourcingExample.Event.MoneyTransfer
  alias EventSourcingExample.Event.Withdraw

  def money_transfer(%{private: %{auth: %{user: account}}} = conn, %{
        "to_account_number" => to_account_number,
        "amount" => amount
      }) do
    event_result =
      %MoneyTransfer{
        from_account_number: account.account_number,
        to_account_number: to_account_number,
        amount: amount
      }
      |> Bus.forward_event()

    case event_result do
      {:ok, _} ->
        json(conn, "ok")

      {:error, {message, _}} ->
        conn
        |> put_status(400)
        |> json(message)
    end
  end

  def withdraw(%{private: %{auth: %{user: account}}} = conn, %{"amount" => amount}) do
    event_result =
      %Withdraw{account_number: account.account_number, amount: amount}
      |> Bus.forward_event()

    case event_result do
      {:ok, _} ->
        json(conn, "ok")

      {:error, {message, _}} ->
        conn
        |> put_status(400)
        |> json(message)
    end
  end
end
