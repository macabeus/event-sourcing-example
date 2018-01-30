defmodule EventSourcingExample.Event.NewAccount do
  @enforce_keys [:email, :password]
  defstruct [:email, :password, :card_number]
end
