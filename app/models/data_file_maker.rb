class DataFileMaker

  @queue = 'data'

  # TODO - logging here is bad; improve. I'm using #error just to ensure it shows up in the log, but that's probably subprime.
  def self.perform(args)
    Rails.logger.error "++ #{Time.now.strftime('%F %T')} DataFileMaker: #{args.values.join(', ')}"
    # Once upon a time, a job was skipped because it didn't exist... but it should have.
    # I assume this was a case of slight slave lag and bad timing, so to ensure
    # that doesn't cause a problem:
    # DataSearchFile.with_master do
      if DataSearchFile.exists?(args["data_file_id"])
        begin
          df = DataSearchFile.find(args["data_file_id"])
          overflow = df.build_file
          
          if overflow
            rejected = [:id, :completed_at, :created_at, :updated_at, :hosted_file_url, :row_count]
            new_df = DataSearchFile.create!(df.attributes.reject{|k| rejected.include? k})
            new_df.file_number = df.file_number + 1
            Resque.enqueue(DataFileMaker, data_file_id: new_df.id)
          end
        rescue => e
          Rails.logger.error "   FAILED: #{e.backtrace}"
        end
      else
        Rails.logger.error "   Data file #{args["data_file_id"]} doesn't exist, assuming canceled."
      end
    # end
    Rails.logger.error "   Done."
  end

end
