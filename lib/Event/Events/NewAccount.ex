defmodule EventSourcingExample.Event.NewAccount do
  @enforce_keys [:email, :password]
  defstruct [:email, :password, :account_number, :verify_code]
end
