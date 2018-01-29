defmodule EventSourcingExample.Event do
  use Amnesia

  alias EventSourcingExample.Event.NewAccount

  def run(events) when is_list(events) do
    Amnesia.transaction do
      Enum.each(events, &EventSourcingExample.Event.run/1)
    end
  end

  def run(%NewAccount{email: email, password: password}) do
    Database.Account.create_new_account(email, password)
  end
end
