class DataFileMaker

  @queue = 'data'

  def self.perform(args)
    puts "++ #{Time.now.strftime('%F %T')} DataFileMaker: #{args.values.join(', ')}"
    # TODO - error-handling.
    if DataSearchFile.exists?(args["data_file_id"])
      begin
        DataSearchFile.find(args["data_file_id"]).build_file
      rescue => e
        puts "   FAILED: #{e.message}"
      end
    else
      puts "   Data file #{args["data_file_id"]} doesn't exist, assuming canceled."
    end
    puts "   Done."
  end

end
