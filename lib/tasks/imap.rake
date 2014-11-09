namespace :imap do
  task :client => :environment do
    Log.info("Starting an IMAP Client process...")

    # Read environment variables.
    config = {}
    config[:stress_test_mode]   = (ENV['STRESS_TEST_MODE'] == "true")
    config[:num_worker_threads] = (ENV['NUM_WORKER_THREADS'] || 5).to_i
    config[:max_user_threads]   = (ENV['MAX_USER_THREADS']   || 5).to_i
    config[:max_email_size]     = (ENV['MAX_EMAIL_SIZE']     || (1024 * 1024)).to_i

    require 'imap_client'
    ImapClient::Daemon.new(config).run
  end

  task :test_server => :environment do
    Log.info("Starting an IMAP Test Server process...")
    ImapDaemonHeartbeat.destroy_all

    # Read environment variables.
    config = {}
    config[:port]              = (ENV['PORT']              || 10143).to_i
    config[:max_emails]        = (ENV['MAX_EMAILS']        || 1000).to_i
    config[:emails_per_minute] = (ENV['EMAILS_PER_MINUTE'] || 500).to_i
    config[:enable_chaos]      = (ENV['ENABLE_CHAOS'] == "true")

    require 'imap_test_server'
    ImapTestServer::Daemon.new(config).run
  end
end
