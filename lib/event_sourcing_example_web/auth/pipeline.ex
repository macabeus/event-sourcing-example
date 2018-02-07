defmodule EventSourcingExampleWeb.Auth.Pipeline do
  use Guardian.Plug.Pipeline, otp_app: :event_sourcing_example,
                              module: EventSourcingExampleWeb.Auth.Guardian,
                              error_handler: EventSourcingExampleWeb.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, ensure: true
end
