defmodule EventSourcingExampleWeb.AccountController do
  use EventSourcingExampleWeb, :controller

  alias EventSourcingExample.Bus
  alias EventSourcingExample.Event.NewAccount

  def post(conn, %{"email" => email, "password" => password}) do
    event_result =
      %NewAccount{email: email, password: password}
      |> Bus.forward_event()

    case event_result do
      {:ok, new_account} ->
        json conn, %{email: new_account.email}

      {:error, message} ->
        conn
        |> put_status(400)
        |> json(message)
    end
  end
end
