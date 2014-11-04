namespace :imap do
  task :daemon => :environment do
    print "Starting an IMAP daemon process..."

    print "AUTO: #{Rails.application.config.autoload_paths}\n"

    config = {}
    [:num_worker_threads, :max_user_threads, :max_email_size].each do |key|
      env_key = key.to_s.upcase
      config[key] = ENV[env_key].to_i if ENV[env_key].present?
    end

    IMAP::Daemon.new(config).run
  end
end
