namespace :imap do

  def env_to_config(keys)
    config = {}
    keys.each do |key|
      env_key = key.to_s.upcase
      config[key] = ENV[env_key].to_i if ENV[env_key].present?
    end
    config
  end

  task :client => :environment do
    Log.info("Starting an IMAP Client process...")

    config = env_to_config([:num_worker_threads,
                            :max_user_threads,
                            :max_email_size])

    require 'imap_client'
    ImapClient::Daemon.new(config).run
  end

  task :test_server => :environment do
    Log.info("Starting an IMAP Test Server process...")
    ImapDaemonHeartbeat.destroy_all

    config = env_to_config([:port,
                            :emails_per_minute,
                            :max_emails,
                            :enable_chaos])

    require 'imap_test_server'
    ImapTestServer::Daemon.new(config).run
  end
end
