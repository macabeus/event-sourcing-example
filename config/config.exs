# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the Mailer
config :event_sourcing_example, EventSourcingExample.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_PRIVATE_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN")

# Configures the endpoint
config :event_sourcing_example, EventSourcingExampleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "NlOGbgvKz8oV1GzEwqOIngIdYMNu8/9m04dae+j7Qy2/1nQlARXQeJiott+ji6En",
  render_errors: [view: EventSourcingExampleWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: EventSourcingExample.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
