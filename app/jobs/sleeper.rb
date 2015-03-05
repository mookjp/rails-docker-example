class Sleeper
  @queue = :sleep

  def self.perform(seconds)
    # TODO: Add message to logger.
    sleep(seconds)
  end
end