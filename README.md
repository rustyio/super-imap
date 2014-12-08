[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/rustyio/grimace)

# Grimace - A scalable IMAP listener.

Grimace triggers a webhook when new email arrives in an IMAP inbox. It
is an open-source (MIT Licensed), cloud-based microservice written in
Ruby / Rails. Grimace is an alternative to Context.io and contains a
subset of Context.io Lite API functionality.

The workflow is as follows:

* Connect to an IMAP account on your user's behalf. (Yes, Grimace handles the OAuth authentication dance for you.)
* Wait for a new email message.
* Trigger a webhook to your application with the contents of the email message.

[FiveStreet](http://www.fivestreet.com) built Grimace to solve scaling
issues as we grew 7000% in weekly email volume over the past
year. Grimace can scale to tens of thousands of users.

Grimace currently supports the following authentication methods:

* Gmail OAuth 1.0
* Gmail OAuth 2.0
* Plain authentication (username / password)

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

# Configuration

First, configure a new partner with a Gmail OAuth 2.0 connection:

1. Create a new partner. Set webhooks to notify your application of the following events:
   * A new email has arrived.
   * A user has connected their email account.
   * A user has disconnected their email account.
2. Create a new IMAP connection under the partner. Get your
   credentials here: https://console.developers.google.com/project;
   read more here:
   https://developers.google.com/accounts/docs/OpenIDConnect
3. Create a new user under the IMAP connection.

## Data Model

Grimace has:

* **IMAP Providers** - Configures an authentication transport
  mechanism. For example, there are connection types for "Plain",
  "Gmail OAuth 1.0" and "Gmail OAuth 2.0".
* **Partners** - Create a partner for each application / environment
  that will use Grimace.
* **Partner Connection** - Defines a connection between a partner and
  a given IMAP Provider. Holds, for example, an application's OAuth
  keys.
* **User** - Holds a user's credentials for a specific partner connection.

Users are uniquely identified by a combination of `imap_provider_code`
and `tag`. The tag is chosen by the partner.

## API

All API calls are scoped by partner. To authenticate, send the
Partner's API key using a header or a parameter. (A header is
preferred because it won't normally appear in HTTP logs.)

    # Access the API curl:
    curl -H "Accept: json" \
         -H "x-api-key:APIKEY" \
         https://my-grimace-host.com/api/v1/connections

    # Access the API using the rest-client gem:
    url = "https://my-grimace-host.com/api/v1"
    resource = RestClient::Resource.new(url, :headers => {
      :'x-api-key'  => "$API_KEY$",
      :content_type => :json,
      :accept       => :json
    })
    resource['connections'].get

### /api/v1/connections

#### GET /api/v1/connections

Get a list of connections for the specified partner.

#### POST /api/v1/connections

Create a new connection.

* `imap_provider_code` is required.
* Other required parameters depend on the IMAP Provider used.

### /api/v1/connections/:IMAP_PROVIDER_CODE

#### GET /api/v1/connections/:IMAP_PROVIDER_CODE

Get information about a given connection.

#### PUT /api/v1/connections/:IMAP_PROVIDER_CODE

Update settings for a given connection. The required parameters depend on the IMAP provider used.

#### DELETE /api/v1/connections

Delete a connection and all underlying user data.

### /api/v1/connections/:IMAP_PROVIDER_CODE/users

#### GET /api/v1/connections/:IMAP_PROVIDER_CODE/users

Get a list of users for the specified IMAP Provider.

#### POST /api/v1/connections/:IMAP_PROVIDER_CODE/users

Create a new user.

* `tag` - Required, a unique tag within the scope of a partner
  connection, selected by the partner application.
* Other required parameters depend on the IMAP Provider used.

### /api/v1/connections/:IMAP_PROVIDER_CODE/users/:TAG

#### GET /api/v1/connections/:IMAP_PROVIDER_CODE/users/:TAG

Get information about the given user, including:

* `email` - The IMAP email address to which the user's account is connected.
* `connected_at` - The date when the user's account was connected. Present only if connected.
* `connect_url` - Redirect to this url to connect a user to a provider. For OAuth based IMAP providers, this begins the OAuth dance.
* `disconnect_url` - Redirect to this url to disconnect a user from a provider.

#### PUT /api/v1/connections/:IMAP_PROVIDER_CODE/users/:TAG

Update a user. The required parameters depend on the IMAP provider used.

#### DELETE /api/v1/connections/:IMAP_PROVIDER_CODE/users/:TAG

Archive a user. The user can be restored in the web interface, or by
updating the user (ie: a PUT request.

# Running Grimace

### Development

Run this once:

    # Run this once.
    bundle; rake db:setup db:seed

Then start the server:

    foreman s

Log in as the default user: "admin@example.com" / "password"

### Tests

Run this once:

    RAILS_ENV=test rake db:setup db:seed

Then run all tests:

    rake test:all

### Stress Tests

The stress test exercises the multi-threaded aspects of Grimace, as
well as the error recovery code. To do this, we point the Grimace IMAP
client code against a local IMAP server and generate a bunch of fake emails
for many users.

Additionally, the IMAP server generates 'chaotic' events; it will
intentionally generate incorrect or gibberish responses. The Grimace
IMAP client code is expected to recover gracefully while using a
minimal amount of system resources.

Run this once:

    RAILS_ENV=stress rake db:setup db:seed"

Then run the stress test:

    script/stress-test

### Production

Run this once:

    RAILS_ENV=production rake db:setup db:seed"

Then start the server:

    foreman s -f Procfile

Log in as the default user: "admin@example.com" / "password"

# Future Work

* Configure stress test to report code coverage.
* Make a way to "sweep" a user's inbox, generating webhook events for all emails.

# Contributions

To contribute to this project, please fork and file a pull
request. Small patches will be accepted more quickly than large
patches.
