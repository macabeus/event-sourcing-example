defmodule EventSourcingExample.Event do
  use Amnesia

  alias EventSourcingExample.Event.MoneyTransfer
  alias EventSourcingExample.Event.NewAccount

  def run(%MoneyTransfer{from_account_number: from_account_number, to_account_number: to_account_number, amount: amount} = event) do
    result = Amnesia.transaction do
      Database.Account.money_transfer(from_account_number, to_account_number, amount)
    end

    with {:ok, _} <- result do
      {:ok, event}
    else
      err -> err
    end
  end

  def run(%NewAccount{email: email, password: password, account_number: nil} = event) do
    result = Amnesia.transaction do
      Database.Account.create_new_account(email, password)
    end

    with {:ok, %Database.Account{account_number: account_number}} <- result do
      {:ok, %{event | account_number: account_number}}
    else
      err -> err
    end
  end

  def run(%NewAccount{email: email, password: password, account_number: account_number} = event) do
    result = Amnesia.transaction do
      Database.Account.create_new_account(email, password, account_number)
    end

    with {:ok, _} <- result do
      {:ok, event}
    else
      err -> err
    end
  end
end
