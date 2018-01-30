defmodule EventSourcingExample.Event do
  use Amnesia

  alias EventSourcingExample.Event.MoneyTransfer
  alias EventSourcingExample.Event.NewAccount

  def run(events) when is_list(events) do
    Amnesia.transaction do
      Enum.each(events, &EventSourcingExample.Event.run/1)
    end
  end

  def run(%MoneyTransfer{from_account_number: from_account_number, to_account_number: to_account_number, amount: amount}) do
    Database.Account.money_transfer(from_account_number, to_account_number, amount)
  end

  def run(%NewAccount{email: email, password: password, card_number: card_number}) do
    Database.Account.create_new_account(email, password, card_number)
  end

  def run(%NewAccount{email: email, password: password}) do
    Database.Account.create_new_account(email, password)
  end
end
