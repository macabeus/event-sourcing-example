defmodule EventSourcingExampleWeb.Router do
  use EventSourcingExampleWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", EventSourcingExampleWeb do
    pipe_through :api

    post "/account", AccountController, :post
    get "/verify", VerifyController, :get
  end
end
