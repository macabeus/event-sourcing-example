defmodule EventSourcingExample.Supervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg)
  end

  def init(_args) do
    children = [
      {EventSourcingExample.EventResolver, name: EventSourcingExample.EventResolver},
      {EventSourcingExample.EventLogger, name: EventSourcingExample.EventLogger},
      {EventSourcingExample.Mail, name: EventSourcingExample.Mail},
      {EventSourcingExample.Bus, name: EventSourcingExample.Bus},
      {EventSourcingExample.Snapshotter, name: EventSourcingExample.Snapshotter},

      {EventSourcingExampleWeb.Endpoint, name: EventSourcingExampleWeb.Endpoint}
    ]

    opts = [strategy: :one_for_one, name: EventSourcingExample.Supervisor]
    Supervisor.init(children, opts)
  end
end
