if defined?(Airbrake) && ENV['AIRBRAKE_KEY']
  Airbrake.configure do |config|
    config.api_key = ENV['AIRBRAKE_KEY']
  end
end
