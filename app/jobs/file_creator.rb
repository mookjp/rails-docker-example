# This is useless class as it only creates tmp file
class FileCreator
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  @queue = :filecreator
  @logger = Logger.new(File.join(Rails.root, 'log', 'resque.log'))

  def self.perform(target_dir_path = Settings.tmp_file_dir)
    # Create random name file
    filename = [*1..9, *'A'..'Z', *'a'..'z'].sample(16).join('')
    target_path = File.join(target_dir_path, filename)
    @logger.debug "Start to create tmp file: #{target_path}"
    File.open(target_path, 'w') do |f|
      f.write("This is tmp file; #{target_path}")
    end
    @logger.debug "Finished creating tmp file; #{target_path}!"
  end
end
