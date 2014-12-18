[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/rustyio/super_imap)

# SuperIMAP Overview

SuperIMAP is an inbound mail processor - it triggers a webhook event when
new email arrives in an IMAP inbox. SuperIMAP is useful when you want your application to react to email sent to your users.

[FiveStreet](http://www.fivestreet.com) built SuperIMAP to solve
scaling issues as we grew 7000% in weekly email volume over the past
year. SuperIMAP can scale to tens of thousands of users. SuperIMAP is
an alternative to Context.io and contains a subset of Context.io Lite
API functionality. SuperIMAP is written in Ruby on Rails and is open
source under the MIT license.

The following IMAP authentication methods are supported:

+ Gmail OAuth 1.0
+ Gmail OAuth 2.0
+ Plain authentication (username / password)

## Security

If you use this code, *PLEASE* ensure that you use very strong,
safeguarded passwords, and preferably, make sure your data is
encrypted at rest. It is a big responsibility to hold the keys to
someone's email. Treat it with the appropriate amount of caution.

Other security measures:

+ SSL is *required* in production.
+ Secure data (e.g. passwords and other credentials) are never exposed via the web interface.
+ Sessions are not remembered.
+ Passwords are not recoverable by email.
+ Accounts are locked for an hour after three invalid password attempts.

## Data Model

SuperIMAP has:

* **IMAP Providers** - Configures an authentication transport
  mechanism. For example, there are connection types for "Plain",
  "Gmail OAuth 1.0" and "Gmail OAuth 2.0".
* **Partners** - Create a partner for each application / environment
  that will use SuperIMAP.
* **Partner Connection** - Defines a connection between a partner and
  a given IMAP Provider. Holds, for example, an application's OAuth
  keys.
* **Users** - Defines a user's credentials for a specific partner connection.

Users are uniquely identified by a combination of `imap_provider_code`
and `tag`. The tag is chosen by the partner.

## Using SuperIMAP

First, configure a new partner with a Gmail OAuth 2.0 connection:

1. Create a new partner. Set webhooks to notify your application of the following events:
   * A new email has arrived.
   * A user has connected their email account.
   * A user has disconnected their email account.
2. Create a new IMAP connection under the partner. Get your
   credentials here: https://console.developers.google.com/project;
   read more here:
   https://developers.google.com/accounts/docs/OpenIDConnect

Then, test it out by connecting a single user:

1. Create a new user under a partner's IMAP connection.
2. Click the 'Connect' link to connect the user to an IMAP provider.
3. Send yourself email, and watch the logs!

Finally, write code in your app to create and connect users as follows:

```ruby
    require 'rest-client'

    url = "https://my-app.com/api/v1/connections/GMAIL_OAUTH2/users"
    users = RestClient::Resource.new(url, :headers => {
      :'x-api-key'  => "$API_KEY$",
      :content_type => :json,
      :accept       => :json
    })

    # Create the user.
    users.post(:tag => "MY_USER")

    # Get the connect url.
    response = users["MY_USER"].get
    connect_url = JSON.parse(response)['connect_url']

    # Set up the success and failure callbacks.
    callbacks = {
      :success => "http://my-app.com/connect_callback?success=1",
      :failure => "http://my-app.com/connect_callback?failure=1"
    }

    # Redirect the user to the connect url.
    redirect_to connect_url  + "?" + callbacks.to_query
```

```ruby
    url = "https://my-host.com/api/v1/connections/GMAIL_OAUTH2/users"
    users = RestClient::Resource.new(url, :headers => {
      :'x-api-key'  => "$API_KEY$",
      :content_type => :json,
      :accept       => :json
    })

    # Later, if you want to disconnect the user.
    response = users["MY_USER"].get
    disconnect_url = JSON.parse(response)['disconnect_url']

    # Set up the success and failure callbacks.
    callbacks = {
      :success => "http://my-app.com/disconnect_callback?success=1"
    }

    # Redirect the user to the disconnect url.
    redirect_to disconnect_url  + "?" + callbacks.to_query
```

## Webhooks

+ All webhooks are dispatched through delayed jobs.
+ Webhooks will be retried up to 6 times, with exponential backoff.
+ Webhooks will fail if the receiving server takes more than 30 seconds to respond.
+ Webhooks expect a success response (HTTP code 200 - 206).
+ A "Forbidden" response code of 403 will automatically archive the user.
+ Any other response codes count as an error, and will trigger another webhook attempt.

All webhooks are signed. You can validate the signature as follows:

```ruby
    # Parse the incoming JSON body.
    json_params = JSON.parse(request.raw_post)

    # Calculate expected signature.
    digest    = OpenSSL::Digest.new('sha256')
    api_key   = Rails.application.config.super_imap_api_key
    sha1      = json_params['sha1']
    timestamp = json_params['timestamp']
    expected_signature = OpenSSL::HMAC.hexdigest(digest, api_key, "#{timestamp}#{sha1}")

    # Get actual signature.
    actual_signature = json_params['signature']

    # Compare signatures.
    valid = expected_signature == actual_signature
```

#### New Mail Webhook

Called when a new mail arrives in a user's inbox.

+ `timestamp` - Timestamp the webhook was sent. Seconds since Jan 1, 1970.
+ `sha1` - The SHA1 hash of the rfc822 parameter.
+ `imap_provider_code` - The IMAP provider code (e.g. "GMAIL_OAUTH2")
+ `user_tag` - The user's tag.
+ `envelope - The email envelope, including date, subject, from, sender, reply_to, to, cc, bcc, in_reply_to, and message_id.
+ `rfc822` - The raw body of the email. http://www.w3.org/Protocols/rfc822/

#### User Connected Webhook

Called when a user has successfully authenticated with an IMAP
provider. Only applies to OAuth connections at the moment.

+ `timestamp` - Timestamp the webhook was sent. Seconds since Jan 1, 1970.
+ `sha1` - The SHA1 hash of the user's tag.
+ `imap_provider_code` - The IMAP provider code (e.g. "GMAIL_OAUTH2")
+ `user_tag` - The user's tag.
+ `email` - The email address with which the user authenticated.

#### User Disconnected Webhook

Called when a user has disconnected from an IMAP provider. Only
applies to OAuth connections at the moment.

+ `timestamp` - Timestamp the webhook was sent. Seconds since Jan 1, 1970.
+ `sha1` - The SHA1 hash of the user's tag.
+ `imap_provider_code` - The IMAP provider code (e.g. "GMAIL_OAUTH2")
+ `user_tag` - The user's tag.

## Running SuperIMAP

#### Architecture

SuperIMAP consists of 3 different processes:

+ 'web' - Serves the admin interface and the API.
+ 'imap_client' - Handles the task of connecting to IMAP providers and listening for email.
+ 'worker' - Processes background jobs generated by the 'imap_client' process.

The Imap Client does the heavy lifting. By default, each IMAP Client
is configured to handle 500 users. You can change this, and other settings, through environment variables:

+ `MAX_USER_THREADS` - Change the maximum number of user threads. Default is 500.
+ `NUM_WORKER_THREADS` - Change the number of worker threads. Default is 5.
+ `MAX_EMAIL_SIZE` - Change the maximum email size. Default is 1 MiB (1,048,576 bytes).
+ `TRACER_INTERVAL` - Interval, in seconds, between outgoing tracer emails. Default is 600 seconds (10 minutes).
+ `NUM_TRACERS` - Number of tracers to send at the end of each tracer interval. Default is 3.

#### Scaling

To scale SuperIMAP, you will mainly want to increase the number of IMAP
Client processes. The IMAP Client processes automatically publish a
heartbeat every 10 seconds. Other instances look for this heartbeat
and re-calculate which neighboring processes are alive based on any
processes that have published a heartbeat within the last 30 seconds.

The IMAP Client processes re-balance users every 10 seconds. If no new
instances have entered or left the pool, then re-balancing will have
no effect.

If a new IMAP Client instance is started, then a small number of users
will be taken from each running instance and handed to the new
instance. If one of the IMAP Client instances is stopped is removed
from the pool, then it's users will be evenly distributed to the
remaining instances (assuming they are still below the
`MAX_USER_THREADS` threshold.)

There is no "master" process that decides which IMAP Client process
should handle a given user. SuperIMAP uses a
[Rendezvous Hash](http://en.wikipedia.org/wiki/Rendezvous_hashing) to
allow IMAP Client instances to agree on how to evenly assign users
without any central coordination.

#### Operations

SuperIMAP publishes some useful monitoring information in the logs.
This includes:

+ `imap_client.user_thread.count` - The size of the imap client work queue. Backups may indicate that your servers are overloaded.
+ `imap_client.total_emails_processed` - The total number of emails processed since the instance was started.
+ `imap_client.work_queue.length` - The number of user threads. This indicates how many users are connected on a given IMAP Client instance.
+ `work_queue.latency` - The latency, in seconds, between when an item is added to the work queue and when it is processed.

These metrics are published in a format that can be consumed by the
Librato Add-On in Heroku. See
https://devcenter.heroku.com/articles/librato#custom-log-based-metrics
for more information.

Apart from keeping an eye on these metrics, SuperIMAP should need no other regular metrics.

You may also want to keep an eye out for any failing Delayed Job tasks. You can view these from the Admin site.

#### Tracer Emails

SuperIMAP has the ability to give you useful monitoring information
through "tracer emails". The system will send a specially formatted
email to an account, wait for the incoming email, and log the
results. The logs can be accessed through the "Tracer Logs" tab.

To enable Tracer Emails, navigate to a user and check the "Enable
Tracer" checkbox. It is recommended that you create a few dummy email
addresses to use for tracer emails.

By default, a cluster of three tracers are sent every ten minutes from
each `imap_client` instance to a random tracer-enabled user managed by
that instance.

Keep in mind that this could generate a lot of email. Three emails
every ten minutes works out to over 432 emails per day.

#### Development Environment

Run this once:

    # Run this once.
    bundle; rake db:setup db:seed

Then start the server:

    foreman s

Log in as the default user: "admin@example.com" / "password"

#### Production Environment

Run this once:

    RAILS_ENV=production rake db:setup db:seed"

Then start the server:

    foreman s -f Procfile

Log in as the default user: "admin@example.com" / "password", and **change the username / password immediately!**

#### Testing

Run this once:

    RAILS_ENV=test rake db:setup db:seed

Then run all tests:

    rake test:all

#### Stress Testing

The stress test exercises the multi-threaded aspects of SuperIMAP, as
well as the error recovery code. To do this, we point the SuperIMAP IMAP
client code against a local IMAP server and generate a bunch of fake emails
for many users.

Additionally, the IMAP server generates 'chaotic' events; it will
intentionally generate incorrect or gibberish responses. The SuperIMAP
IMAP client code is expected to recover gracefully while using a
minimal amount of system resources.

Run this once:

    RAILS_ENV=stress rake db:setup db:seed"

Then run the stress test:

    script/stress-test

## Future Work

* Configure stress test to report code coverage.
* Make a way to "sweep" a user's inbox, generating webhook events for all emails.

## Contributions

To contribute to this project, please fork and file a pull
request. Small patches will be accepted more quickly than large
patches.

## API

All API calls are scoped by partner. To authenticate, send the
Partner's API key using a header or a parameter. (A header is
preferred because it won't normally appear in HTTP logs.)

```sh
    # Access the API curl:
    curl -H "Accept: json" \
         -H "x-api-key:APIKEY" \
         https://my-host.com/api/v1/connections
```


```ruby
    # Access the API using the rest-client gem:
    url = "https://my-host.com/api/v1"
    resource = RestClient::Resource.new(url, :headers => {
      :'x-api-key'  => "$API_KEY$",
      :content_type => :json,
      :accept       => :json
    })
    resource['connections'].get
```
___

#### /api/v1/connections

**GET**

Get a list of connections for the specified partner.

**POST**

Create a new connection.

* `imap_provider_code` is required.
* Other required parameters depend on the IMAP Provider used.

___

#### /api/v1/connections/:IMAP_PROVIDER_CODE

**GET**

Get information about a given connection.

**PUT**

Update settings for a given connection. The required parameters depend on the IMAP provider used.

**DELETE**

Delete a connection and all underlying user data.

___

#### /api/v1/connections/:IMAP_PROVIDER_CODE/users

**GET**

Get a list of users for the specified IMAP Provider.

**POST**

Create a new user.

* `tag` - Required, a unique tag within the scope of a partner
  connection, selected by the partner application.
* Other required parameters depend on the IMAP Provider used.

___

#### /api/v1/connections/:IMAP_PROVIDER_CODE/users/:TAG

**GET**

Get information about the given user, including:

* `email` - The IMAP email address to which the user's account is connected.
* `connected_at` - The date when the user's account was connected. Present only if connected.
* `connect_url` - Redirect to this url to connect a user to a provider. For OAuth based IMAP providers, this begins the OAuth dance.
* `disconnect_url` - Redirect to this url to disconnect a user from a provider.

**PUT**

Update a user. The required parameters depend on the IMAP provider used.

**DELETE**

Archive a user. The user can be restored in the web interface, or by
updating the user (ie: a PUT request.

# License

The MIT License (MIT)

Copyright (c) 2014 Rusty Klophaus / FiveStreet.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
