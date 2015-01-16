class MyLogger
  def initialize
  end

  def exception(exception)
    msg = "#{exception.class} (#{exception.message}):\n    " +
          clean_backtrace(exception).join("\n    ")
    self.error(msg)

    # Trigger an exception email...
    if defined?(Airbrake)
      Airbrake.notify(exception)
    end
  rescue => e
    print e.to_s
  end

  def clean_backtrace(exception)
    if backtrace = exception.backtrace
      if defined?(RAILS_ROOT)
        return backtrace.map { |line| line.sub RAILS_ROOT, '' }
      else
        return backtrace
      end
    else
      return []
    end
  end

  def librato(mode, key, value)
    source = ENV['DYNO']
    if source
      info("source=#{source} #{mode}\##{key}=#{value}")
    else
      info("#{mode}\##{key}=#{value}")
    end
  end

  private

  def method_missing(method, *args, &block)
    Rails.logger.send(method, *args, &block)
  end
end

Log = MyLogger.new()
