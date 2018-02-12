<h1 align="center"> EventSourcingExample </h1>
<p align="center">
  <img src="https://i.imgur.com/qnsAPBD.png" width=120>
</p>

>A vanilla example app about **event sourcing** architecture using Elixir

# What is "event sourcing" architecture?

In an event sourcing application, each change of the state is made by an "event", that is recorded and, reprocessing the recorded events, we can can rebuild the current state, or any previous state. A good example of an event sourcing application is a version-control system, like git. The commits are the events and we can rebuild any previous state of the project reprocessing this events.

The event log is a very useful feature of this architecture, because we'll have a strong audit capability to check if something weird happened, and we can explore alternative histories by injecting hypothetical events.

Since we can rebuild the state of application reliably, we can work using an in-memmory database to store the current state. The advantage of an in-memmory database is the high performance, since everything is being done in-memory with no IO or remote calls to database systems.

To learning more about event sourcing:
* **Talk:** [GOTO 2017 - The Many Meanings of Event-Driven Architecture - Martin Fowler](https://www.youtube.com/watch?v=STKCRSUsyP0)
* **Blogpost:** [What do you mean by "Event-Driven"? - Martin Fowler](https://martinfowler.com/articles/201701-event-driven.html)
* **Talk (Brazillian Portuguese):** [CQRS/ES com Elixir - Bernardo Amorim](https://pt-br.eventials.com/locaweb/cqrs-es-com-elixir-com-bernardo-amorim/)

# What is this application?

This application is a (very simple) bank server, where users can open an account (with email verification), transfer money between accounts and withdraw. When a user creates a new account, he will receive $1.000 - yeah, this bank is very kind. Each of actions that users can do is an event. I'll describe more of it bellow.

# How to run

Firstly, download it:

```
> git clone https://github.com/macabeus/event-sourcing-example.git
> cd "event-sourcing-example"
```

Then, create the database:

```
> mix amnesia.create -d Database --memory
```

Create an account on [Mailgun](https://www.mailgun.com/) (it's free!) and set your private key and domain:

```
> export MAILGUN_API_PRIVATE_KEY=key-e00000aa0aa00000a000aa00a000aa00
> export MAILGUN_DOMAIN=sandbox00aa00000a000000a0e0a000000000aa.mailgun.org
```

Test if everything is ok:

```
> mix test
```

Then, start the Phoenix API:

```
> mix phx.server
```

[You can read the API doc on Postman.](https://documenter.getpostman.com/view/1363558/event-sourcing-example/RVftksGU)

Maybe you want view the events recorded. You can see it using:

```
> iex -S mix
> EventSourcingExample.EventLogger.view_logs()
```

# How event sourcing was applied in this project?

Since this is a project for studying purposes, I'll explain how I created this project, the logic and design.

<p align="center">
  <img src="https://i.imgur.com/5B5pJc1.png">
</p>

## Process and bus pipeline

The application has 5 importants process started on Supervisor: Bus, EventResolver, EventLogger, Snapshotter and Mail. We only send events to bus, and it forward to the others process mentioned.

The bus is very simple. We don't need register a process on bus, because we already know all the process on compilation time. When we send an event to the bus, it will forward the event to process in this order: EventResolver, EventLogger (if need), Snapshotter (if need) and Mail (if need).

Why the "if need"? Easy to answer! When a user sends a new event, we want run the entire pipeline (because we need resolve the event, log it, send e-mail...). But, if the application crashed and we need restore the previous state, we don't need re-log or send an email again. We only need resolve. Because of it, we can choose the pipeline to forward an event. "Teste" is another situation where we don't need run the entire pipeline.

## Events

In the [events.ex](https://github.com/macabeus/event-sourcing-example/blob/master/lib/event_sourcing_example/events.ex) is defined all events that our application can resolve. Each event is a struct. We have 4 events (NewAccount, VerifyAccount, MoneyTransfer and Withdraw). When an event is resolved it changes the application state. For example, when the MoneyTransfer is resolved the state is changed because someone receives money and someone loses money.

The NewAccount event needs a special attencion, because it's an example of non-deterministic event, because we have two values that is random: account number and verify code. A event is non-deterministic when we can't know the all efects only with the application state and event parameters. We'll speak more about it bellow.

We fristly resolve the event using the EventResolver process, and then store it (that is, the event type and parameters). Is important frist resolve the event and only then store because we frist know if the event is correct (for example, if the account exists). In the case of non-deterministic events is more important because after resolve it, we know the non-deterministic fields.

For each non-deterministic events, the EventResolver process need have at least two way to resolve this events: when the user sends by API (that is, when we haven't the value of non-deterministic fields), and when we restoring the state of the application (that is, when we have the value of non-deterministic fields).

Furthermore, two process sends e-mail: NewAccount, that send a link to verify the account, and Withdraw, that say the money debited on account.

## Database

We have two databases: Amnesia (Elixir wrapper of Mnesia) and DETS. One of greate points of event sourcing is the preference of in-memmory database, and Mnesia is a in-memmory database built-in Erlang. Mnesia is an oriented document store, but, for a bank system, is better a relational database to store the accounts, transactions... Then, the Amnesia give a flavour for Mnesia, also give a better semantic on Elixir code. In order to store the events, I choosed DETS, because using it is possible store and retrive a struct easily.

The function of Snapshotter process is create a copy of Mnesia tables every 5 events is resolved and save the copy on disk, in order to, when we need restore the previous state of application, we don't need resolve each event again.

## API

The Rest API was built using Phoenix. Although Elixir has awesome GraphQL libraries, I choosed to don't use GraphQL because this API doesn't need be highly query-able API.

# In real-life situation

This app is only a simple example. In real-life application many others considerations needs to be made.

For example, maybe your application has sensible data that don't be storage directly. In this example, the project is a "bank". Each financial transactions is an event, and the event has user's card number. Because of event sourcing architecutre, the app needs store whole event, including the card number! We could store the hash os card number, but then the EventResolver needs to resolve using the hash of card number.

And, very important: Elixir already has awesome libraries to create an event sourcing architecture, and one of the very popular libraries is [Commanded](https://github.com/commanded/commanded). In real-life situation, this is the ideal solution. Because of this example app aim to build a naive and vanilla solution about event sourcing, I didn't use it. By the way, this [awesome list](https://github.com/slashdotdash/awesome-elixir-cqrs) has talks and others examples about Elixir + Commanded.

Another consideration for real-life is CQRS pattern. [CQRS is a good pattern for to use with Event Sourcing](https://martinfowler.com/bliki/CQRS.html). In order to simplify this project, I didn't use CQRS pattern in this example app. Again, [the awesome list already mentioned](https://github.com/slashdotdash/awesome-elixir-cqrs) has good study materials about this pattern.
