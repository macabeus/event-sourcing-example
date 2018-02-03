defmodule EventSourcingExample.Mail do
  import Bamboo.Email

  use Amnesia
  use GenServer

  alias EventSourcingExample.Event.NewAccount
  alias EventSourcingExample.Event.Withdraw
  alias EventSourcingExample.Mailer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def send_email_if_need(event) do
    GenServer.cast(__MODULE__, {:send_email_if_need, event})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, :state_doesnt_matter}
  end

  defp get_email(account_number) do
    Amnesia.transaction do
      account = Database.Account.get_account!(%{account_number: account_number})
      account.email
    end
  end

  defp base_email() do
    Bamboo.Email.new_email
    |> from("eventsourcingexample@elixir.com")
  end

  def handle_cast({:send_email_if_need, %NewAccount{email: email, verify_code: verify_code}}, state) do
    base_email()
    |> to(email)
    |> subject("[EVENT SOURCING EXAMPLE] Please verify your account")
    |> text_body("Please verify your account using the code #{verify_code}")
    |> Mailer.deliver_now

    {:noreply, state}
  end

  def handle_cast({:send_email_if_need, %Withdraw{account_number: account_number, amount: amount}}, state) do
    base_email()
    |> to(get_email(account_number))
    |> subject("[EVENT SOURCING EXAMPLE] Withdraw")
    |> text_body("You did withdraw #{amount}")
    |> Mailer.deliver_now

    {:noreply, state}
  end

  def handle_cast({:send_email_if_need, _event}, state) do
    {:noreply, state}
  end
end
