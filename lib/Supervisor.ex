defmodule EventSourcingExample.Supervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg)
  end

  def init(_args) do
    children = [
      {EventSourcingExample.EventResolver, name: EventSourcingExample.EventResolver},
      {EventSourcingExample.EventLogger, name: EventSourcingExample.EventLogger}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
