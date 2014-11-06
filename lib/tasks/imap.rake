namespace :imap do
  task :client => :environment do
    Log.info("Starting an IMAP Client process...")

    config = {}
    [:num_worker_threads, :max_user_threads, :max_email_size].each do |key|
      env_key = key.to_s.upcase
      config[key] = ENV[env_key].to_i if ENV[env_key].present?
    end

    require 'imap_client'
    ImapClient::Daemon.new(config).run
  end

  task :test_server => :environment do
    Log.info("Starting an IMAP Test Server process...")
    ImapDaemonHeartbeat.destroy_all
    require 'imap_test_server'
    daemon = ImapTestServer::Daemon.new(:port => 10143)
    daemon.run
  end
end
