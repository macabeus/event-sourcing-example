defmodule EventSourcingExampleWeb.VerifyController do
  use EventSourcingExampleWeb, :controller

  alias EventSourcingExample.Bus
  alias EventSourcingExample.Event.VerifyAccount

  def get(conn, %{"account_number" => account_number, "code" => code}) do
    event_result =
      %VerifyAccount{account_number: account_number, code: code}
      |> Bus.forward_event()

    case event_result do
      {:ok, _verify_result} ->
        json(conn, "ok")

      {:error, {message, _}} ->
        conn
        |> put_status(400)
        |> json(message)

      {:error, message} ->
        conn
        |> put_status(400)
        |> json(message)
    end
  end
end
