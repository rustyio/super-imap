# TODO

+ Failure webhook.
  + User no longer authorized.
+ Handle response code to archive a user.
+ Archive a user, modify uniqueness check.
+ Disconnect when a user is archived.
+ Heroku one click deployment file.

## Use Cases:

Connect a User:

+ '/connect?api_key=?success=?&failure=?'
+ Receive a URL.
+ Redirect user to URL.

## Topology

+ Rails project.
+ script/imap_worker for doing the work.
+ Scale using database.
+ Stats in database and console.
