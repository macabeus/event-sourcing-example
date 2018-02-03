defmodule EventSourcingExample.Event.VerifyAccount do
  @enforce_keys [:account_number, :code]
  defstruct [:account_number, :code]
end
