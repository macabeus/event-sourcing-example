defmodule EventSourcingExample.Event.VerifyAccount do
  @enforce_keys [:account_number]
  defstruct [:account_number]
end
