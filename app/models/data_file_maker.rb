class DataFileMaker

  @queue = 'data'

  # TODO - specs !  (This has none.)

  def self.perform(args)
    puts "++ #{Time.now.strftime('%F %T')} DataFileMaker: #{args.values.join(', ')}"
    # Once upon a time, a job was skipped because it didn't exist... but it should have.
    # I assume this was a case of slight slave lag and bad timing, so to ensure
    # that doesn't cause a problem:
    DataSearchFile.with_master do
      if DataSearchFile.exists?(args["data_file_id"])
        begin
          DataSearchFile.find(args["data_file_id"]).build_file
        rescue => e
          puts "   FAILED: #{e.message}"
        end
      else
        puts "   Data file #{args["data_file_id"]} doesn't exist, assuming canceled."
      end
    end
    puts "   Done."
  end

end
