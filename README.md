<h1 align="center"> EventSourcingExample </h1>
<p align="center">
  <img src="https://i.imgur.com/qnsAPBD.png" width=120>
</p>

>A vanilla example app about **event sourcing** architecture using Elixir

# What is "event sourcing" architecture?

In an event sourcing application, each change of the state is made by an "event", that is recorded and, reprocessing the recorded events, we can can rebuild the current state, or any previous state. A good example of an event sourcing application is a version-control system, like git. The commits are the events and we can rebuild any previous state of the project reprocessing these events.

The event log is a very useful feature of this architecture, because we'll have a strong audit capability to check if something weird happened, and we can explore alternative histories by injecting hypothetical events.

Since we can rebuild the state of application reliably, we can work using an in-memory database to store the current state. The advantage of an in-memory database is the high performance, since everything is being done in-memory with no IO or remote calls to database systems.

To learn more about event sourcing:
* **Talk:** [GOTO 2017 - The Many Meanings of Event-Driven Architecture - Martin Fowler](https://www.youtube.com/watch?v=STKCRSUsyP0)
* **Blogpost:** [What do you mean by "Event-Driven"? - Martin Fowler](https://martinfowler.com/articles/201701-event-driven.html)
* **Talk (Brazillian Portuguese):** [CQRS/ES com Elixir - Bernardo Amorim](https://pt-br.eventials.com/locaweb/cqrs-es-com-elixir-com-bernardo-amorim/)

# What is this application?

This application is a (very simple) bank server, where users can open an account (with email verification), transfer money between accounts and withdraw. When a user creates a new account, he will receive $1.000 - yeah, this bank is very kind. Each actions users can do is an event. I'll describe more of it bellow.

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

Maybe you want to view the events recorded. You can see it using:

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

The application has 5 important processes which started on Supervisor: Bus, EventResolver, EventLogger, Snapshotter and Mail. We only send events to bus, and it forwards to the other processes mentioned.

The bus is very simple. We don't need to register a process on bus, because we already know all the processes on compilation time. When we send an event to the bus, it will forward the event to the processes in this order: EventResolver, EventLogger (if needed), Snapshotter (if needed) and Mail (if needed).

Why the "if needed"? Easy to answer! When a user sends a new event, we want to run the entire pipeline (because we need to resolve the event, log it, send an e-mail...). But if the application crashed and we needed to restore the previous state, we wouldn't need to re-log or send an email again. We only need to resolve. Because of it, we can choose the pipeline to forward an event. "Test" is another situation where we don't need to run the entire pipeline.

## Events

In the [events.ex](https://github.com/macabeus/event-sourcing-example/blob/master/lib/event_sourcing_example/events.ex) is defined all of the events that our application can resolve. Each event is a struct. We have 4 events (NewAccount, VerifyAccount, MoneyTransfer and Withdraw). When an event is resolved it changes the application state. For example, when the MoneyTransfer is resolved the state is changed because someone receives money and someone loses money.

The NewAccount event needs special attention, because it's an example of non-deterministic event, and we have two values that are random: account number and verify code. An event is non-deterministic when we can't know the all efects only with the application state and event parameters. We'll talk more about it bellow.

We firstly resolve the event using the EventResolver process, and then store it (that is, the event type and parameters). It is important to resolve the event first and only then store because we first know if the event is correct (for example, if the account exists). In the case of non-deterministic events it is more important because after we resolving it, we know the non-deterministic fields.

For each non-deterministic event, the EventResolver process need to have at least two ways to resolve these events: when the user sends by API (that is, when we haven't the value of non-deterministic fields), and when we restore the state of the application (that is, when we have the value of non-deterministic fields).

Furthermore, two processes send an e-mail: NewAccount, that sends a link to verify the account, and Withdraw, that says the money was debited from the account.

## Database

We have two databases: Amnesia (Elixir wrapper of Mnesia) and DETS. One of the greatest points of event sourcing is the preference of in-memory database, and Mnesia is an in-memory database built-in Erlang. Mnesia is an oriented document store, but, for a bank system, it is better to use a relational database to store the accounts, transactions... Then, the Amnesia gives a flavour for Mnesia, also gives a better semantic on Elixir code. In order to store the events, I chose DETS, because using it is possible to store and retrive a struct easily.

The function of Snapshotter process is to create a copy of Mnesia tables every time 5 events are resolved and save the copy on disk, in order to, when we need to restore the previous state of the application, we don't need to resolve each event again.

## API

The Rest API was built using Phoenix. Although Elixir has awesome GraphQL libraries, I chose not to use GraphQL because this API doesn't need to be highly query-able API.

# In real-life situation

This app is only a simple example. In real-life application many other considerations need to be made.

For example, maybe your application has sensible data that is not stored directly. In this example, the project is a "bank". Each financial transaction is an event, and the event has user's card number. Because of event sourcing architecutre, the app needs to store the whole event, including the card number! We could store the hash of card number, but then the EventResolver needs to resolve using the hash of card number.

And, very important: Elixir already has awesome libraries to create an event sourcing architecture, and one of the most popular libraries is [Commanded](https://github.com/commanded/commanded). In a real-life situation, this is the ideal solution. Because this example app aims to build a naive and vanilla solution about event sourcing, I didn't use it. By the way, this [awesome list](https://github.com/slashdotdash/awesome-elixir-cqrs) has talks and other examples about Elixir + Commanded.

Another consideration for real-life situations is CQRS pattern. [CQRS is a good pattern to use with Event Sourcing](https://martinfowler.com/bliki/CQRS.html). In order to simplify this project, I didn't use CQRS pattern in this example app. Again, [the awesome list already mentioned](https://github.com/slashdotdash/awesome-elixir-cqrs) has good study materials about this pattern.
