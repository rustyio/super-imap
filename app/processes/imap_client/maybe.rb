# A control structure that we use because we wish we had monads. Run a
# series of code blocks. A block is considered successful if it
# returns true and doesn't throw any exceptions. If a block is not
# successful, we skip the remaining blocks.
class Maybe
  attr_accessor :successful, :exception

  def initialize
    self.successful = true
  end

  def run(&block)
    if self.successful
      yield || self.successful = false
    end
  rescue Exception => e
    self.successful = false
    self.exception = e
  end

  def finish
    if self.exception
      raise self.exception
    else
      return self.successful
    end
  end
end
