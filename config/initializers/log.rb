class ActiveSupport::Logger
  def exception(e)
    Rails.logger.error(e)

    # Trigger an exception email...
    if defined?(Airbrake)
      parameters = { :buffer => Log.dump_buffer("; ") }
      Airbrake.notify(exception, :parameters => parameters)
    end
  end
end

Log = Rails.logger
