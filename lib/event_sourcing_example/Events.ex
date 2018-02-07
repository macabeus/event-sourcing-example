defmodule EventSourcingExample.Event do
  defmodule MoneyTransfer do
    @enforce_keys [:from_account_number, :to_account_number, :amount]
    defstruct [:from_account_number, :to_account_number, :amount]
  end

  defmodule NewAccount do
    @enforce_keys [:email, :password]
    defstruct [:email, :password, :account_number, :verify_code]
  end

  defmodule VerifyAccount do
    @enforce_keys [:account_number, :code]
    defstruct [:account_number, :code]
  end

  defmodule Withdraw do
    @enforce_keys [:account_number, :amount]
    defstruct [:account_number, :amount]
  end
end
