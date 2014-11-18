# TODO

+ Test the Connection API.
+ Test the User API.
+ Add the code to wire up a user.

+ Failure webhook.
  + User no longer authorized.
+ Handle response code to archive a user.

## Use Cases:

Connect a User:

+ '/connect?api_key=?success=?&failure=?'
+ Receive a URL.
+ Redirect user to URL.

Disconnect a User:

+ '/disconnect?api_key=?&uid=?

## Topology

+ Rails project.
+ script/imap_worker for doing the work.
+ Scale using database.
+ Stats in database and console.
