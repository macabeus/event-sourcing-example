defmodule EventSourcingExampleWeb.Auth.ErrorHandler do
  import Plug.Conn

  def auth_error(conn, {_type, reason}, _opts) do
    conn
    |> put_resp_content_type("text/json")
    |> send_resp(401, "\"Invalid authorization token\"")
  end
end
