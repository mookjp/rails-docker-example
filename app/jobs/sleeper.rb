class Sleeper
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  @queue = :sleep
  @logger = Logger.new(File.join(Rails.root, 'log', 'resque.log'))

  def self.perform(seconds)
    # TODO: Add message to logger.
    @logger.debug 'Start sleeping...'
    sleep(seconds)
    @logger.debug 'Finished sleeping'
  end
end