# IMAP Redesign.

rails g model Partner \
    api_key:string \
    name:string \
    success_webhook:string \
    failure_webhook:string

rails g model PartnerCredential \
    oauth_provider:references \
    oauth1_consumer_key:string \
    oauth1_consumer_secret:string \
    oauth2_client_id:string \
    oauth2_client_secret:string

rails g model OauthProvider \
    type:string \
    scope:string \
    site:string \
    request_token_path:string \
    authorize_path:string \
    access_token_path:string

rails g model User \
    partner:references \
    tag:string \
    partner_credential:references \
    last_connected_at:datetime \
    last_email_at:datetime \
    last_uid:integer \
    archived:boolean

rails g model MailLog \
    user:references \
    message_id:string

rails g model TransmitLog \
    mail_log:references \
    response_code:integer \
    response_body:string

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

## Configuration

+ API_KEY
+ GOOGLE_OAUTH_CLIENT_ID
+ GOOGLE_OAUTH_CLIENT_SECRET
+ MESSAGE_WEBHOOK_URL
+ FAILURE_WEBHOOK_URL

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
