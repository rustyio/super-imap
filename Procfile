web:            bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker:         bundle exec rake jobs:work

# Heroku dynos have thread limits. (1x = 256, 2x = 512, px =
# 32767). For 1x and 2x dynos, we set MAX_USER_THREADS way below the
# limit because IMAP also consumes some threads. For px dynos, we use
# foreman to create multiple imap_client instances on a single box.
#
# See https://devcenter.heroku.com/articles/limits#processes-threads

imap_client_1x: NUM_WORKER_THREADS=1 MAX_USER_THREADS=200 bundle exec rake imap:client
imap_client_2x: NUM_WORKER_THREADS=2 MAX_USER_THREADS=500 bundle exec rake imap:client
imap_client_px: bundle exec foreman s -f Procfile.imap-client-px
