defmodule EventSourcingExample.Event do
  use Amnesia

  alias EventSourcingExample.Event.MoneyTransfer
  alias EventSourcingExample.Event.NewAccount
  alias EventSourcingExample.Event.VerifyAccount

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

    with {
      :ok,
      {%Database.Account{account_number: account_number}, %Database.VerifyCode{code: code}}
    } <- result
    do
      updated_event = %{event | account_number: account_number, verify_code: code}
      {:ok, updated_event}
    else
      err -> err
    end
  end

  def run(%NewAccount{email: email, password: password, account_number: account_number, verify_code: verify_code} = event) do
    result = Amnesia.transaction do
      Database.Account.create_new_account(email, password, account_number, verify_code)
    end

    with {:ok, _} <- result do
      {:ok, event}
    else
      err -> err
    end
  end

  def run(%VerifyAccount{account_number: account_number, code: code} = event) do
    Amnesia.transaction do
      case Database.Account.get_account(%{account_number: account_number}) do
        {:ok, account} ->
          Database.Account.verify_account(account, code)
          {:ok, event}

        err ->
          err
      end
    end
  end
end
