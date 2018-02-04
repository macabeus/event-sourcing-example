defmodule EventSourcingExampleWeb.Router do
  use EventSourcingExampleWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", EventSourcingExampleWeb do
    pipe_through :api
  end
end
