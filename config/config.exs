use Mix.Config

config :event_sourcing_example, EventSourcingExample.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_PRIVATE_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN")
