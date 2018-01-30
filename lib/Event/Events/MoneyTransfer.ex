defmodule EventSourcingExample.Event.MoneyTransfer do
  @enforce_keys [:from_account_number, :to_account_number, :amount]
  defstruct [:from_account_number, :to_account_number, :amount]
end
