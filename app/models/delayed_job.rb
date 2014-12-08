class DelayedJob < ActiveRecord::Base
  # Run all existing delayed_job records. Log errors, return true if
  # everything was run.
  def self.flush
    count = 0
    while job = Delayed::Job.where("locked_at IS NULL").first do
      count += 1
      raise "Delayed Job loop?" if count > 10
      begin
        job.invoke_job
        job.destroy
      rescue => e
        print "Problem processing delayed job:\n#{job.to_yaml}"
        raise e
      end
    end
    return true
  end
end
