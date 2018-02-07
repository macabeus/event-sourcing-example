defmodule EventSourcingExample.EventResolver do
  use Amnesia
  use GenServer

  alias EventSourcingExample.Event.MoneyTransfer
  alias EventSourcingExample.Event.NewAccount
  alias EventSourcingExample.Event.VerifyAccount
  alias EventSourcingExample.Event.Withdraw

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def resolve(event) do
    GenServer.call(__MODULE__, {:resolve_event, event})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, :state_doesnt_matter}
  end

  def handle_call({:resolve_many_events, []}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:resolve_event, event}, _from, state) do
    event_result = run(event)
    {:reply, event_result, state}
  end

  defp run(%MoneyTransfer{from_account_number: from_account_number, to_account_number: to_account_number, amount: amount} = event) do
    result = Amnesia.transaction do
      Database.Account.money_transfer(from_account_number, to_account_number, amount)
    end

    with {:ok, _} <- result do
      {:ok, event}
    else
      err -> err
    end
  end

  defp run(%NewAccount{email: email, password: password, account_number: nil} = event) do
    result = Amnesia.transaction do
      Database.Account.create_new_account(email, password)
    end

    with {
      :ok,
      {%Database.Account{password: password_hash, account_number: account_number}, %Database.VerifyCode{code: code}}
    } <- result
    do
      updated_event = %{event | password: password_hash, account_number: account_number, verify_code: code}
      {:ok, updated_event}
    else
      err -> err
    end
  end

  defp run(%NewAccount{email: email, password: password, account_number: account_number, verify_code: verify_code} = event) do
    result = Amnesia.transaction do
      Database.Account.create_new_account(email, password, account_number, verify_code)
    end

    with {:ok, _} <- result do
      {:ok, event}
    else
      err -> err
    end
  end

  defp run(%VerifyAccount{account_number: account_number, code: code} = event) do
    Amnesia.transaction do
      with {:ok, account} <- Database.Account.get_account(%{account_number: account_number}),
           {:ok, _}       <- Database.Account.verify_account(account, code)
      do
        {:ok, event}
      else
        err -> err
      end
    end
  end

  defp run(%Withdraw{account_number: account_number, amount: amount} = event) do
    Amnesia.transaction do
      with {:ok, account} <- Database.Account.get_account(%{account_number: account_number}),
           {:ok, _}       <- Database.Account.withdraw(account, amount)
      do
        {:ok, event}
      else
        err -> err
      end
    end
  end
end
