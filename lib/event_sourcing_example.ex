defmodule EventSourcingExample do
  use Application
  use Amnesia

  alias EventSourcingExample.EventResolver
  alias EventSourcingExample.Event.NewAccount
  alias EventSourcingExample.Event.MoneyTransfer

  def start(_type, _args) do
    EventSourcingExample.Supervisor.start_link([])
  end
end
