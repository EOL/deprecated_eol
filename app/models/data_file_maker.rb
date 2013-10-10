class DataFileMaker

  @queue = 'data'

  def self.perform(args)
    puts "++ DataFileMaker: #{args.values.join(', ')}"
    # TODO - error-handling.
    if DataSearchFile.exists?(args["data_file_id"])
      DataSearchFile.find(args["data_file_id"]).build_file
    else
      puts "   Data file #{args["data_file_id"]} doesn't exist, assuming canceled."
    end
    puts "   Done."
  end

end
