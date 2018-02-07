defmodule EventSourcingExampleWeb.AccountController do
  use Amnesia

  use EventSourcingExampleWeb, :controller

  alias EventSourcingExample.Bus
  alias EventSourcingExample.Event.NewAccount
  alias EventSourcingExampleWeb.Auth.Guardian

  def post(conn, %{"email" => email, "password" => password}) do
    event_result =
      %NewAccount{email: email, password: password}
      |> Bus.forward_event()

    case event_result do
      {:ok, new_account} ->
        json conn, %{account_number: new_account.account_number}

      {:error, message} ->
        conn
        |> put_status(400)
        |> json(message)
    end
  end

  def login(conn, %{"account_number" => account_number, "password" => password}) do
    get_account_result = Amnesia.transaction do
      Database.Account.get_account(%{account_number: account_number, plain_text_password: password})
    end

    with {:ok, account}  <- get_account_result,
         {:ok, token, _} <- Guardian.encode_and_sign(account)
    do
      json conn, %{token: token}
    else
      err ->
        conn
        |> put_status(401)
        |> json(err)
    end
  end
end
