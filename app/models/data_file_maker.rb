class DataFileMaker

  @queue = 'data'

  def self.perform(args)
    puts "++ DataFileMaker: #{args.values.join(', ')}"
    # TODO - error-handling.
    DataSearchFile.find(args["data_file_id"]).build_file
    puts "   ...Done."
  end

end
