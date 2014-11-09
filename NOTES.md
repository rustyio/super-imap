# TODO

+ Turn on multi-server support, measure how many emails we miss.
+ Turn on chaos, measure how many emails we miss.

# Operations

+ Failure webhook? Tracking?
+ Connection retries... rate limiting.

+ Librato metrics.
  + Measure latency around the work queues.

## Goals

1. Open source.
2. Micro-service-ish.
2. Heroku one click service.
3. Scaleable.

## Use Cases

1. Connect a user through OAuth.
2. Wait for incoming messages.
3. Read the messages.
4. Fire a webhook to send the message.
   + Obey response code if the user is no longer authorized.
5. Fire a webhook if a user is no longer valid.
6. Sweep through the entire inbox.

## Use Cases:

Connect a User:

+ '/connect?api_key=?success=?&failure=?'
+ Receive a URL.
+ Redirect user to URL.

Fire a webhook. Delayed Job:

+ Thread pool.
+

## Topology

+ Rails project.
+ script/imap_worker for doing the work.
+ Scale using database.
+ Stats in database and console.
