defmodule EventSourcingExample.Event.Withdraw do
  @enforce_keys [:account_number, :amount]
  defstruct [:account_number, :amount]
end
