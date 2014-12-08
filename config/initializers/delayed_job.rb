# config/initializers/delayed_job.rb

# Update settings.
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.read_ahead          = 10
Delayed::Worker.default_priority    = 10
Delayed::Worker.max_run_time        = 20.minutes
Delayed::Worker.default_queue_name  = "worker"
Delayed::Worker.max_attempts        = 6

if !Delayed::Worker.instance_methods.include?(:handle_failed_job)
  raise "Could not update Delayed::Worker!"
end

# Patch to log errors.
class Delayed::Worker
  alias_method :original_handle_failed_job, :handle_failed_job

  def handle_failed_job(job, error)
    begin
      # Send an alert.
      Log.exception(error)
    rescue => e
      # Shouldn't get here, but if it does, at least log it.
      Log.exception(e)
    end

    # Handle as usual.
    original_handle_failed_job(job, error)
  end
end
