defmodule EventSourcingExample.Mail do
  import Bamboo.Email

  use GenServer

  alias EventSourcingExample.Event.NewAccount
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

  def handle_cast({:send_email_if_need, _event}, state) do
    {:noreply, state}
  end
end
