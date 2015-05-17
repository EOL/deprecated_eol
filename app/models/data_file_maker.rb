class DataFileMaker

  @queue = 'data'

  # TODO - logging here is bad; improve. I'm using #error just to ensure it shows up in the log, but that's probably subprime.
  def self.perform(args)
    Rails.logger.error "++ #{Time.now.strftime('%F %T')} DataFileMaker: #{args.values.join(', ')}"
    # Once upon a time, a job was skipped because it didn't exist... but it should have.
    # I assume this was a case of slight slave lag and bad timing, so to ensure
    # that doesn't cause a problem:
    DataSearchFile.with_master do
      if DataSearchFile.exists?(args["data_file_id"])
        begin
          dsf = DataSearchFile.find(args["data_file_id"])
          response = dsf.build_file
          if !response[:error].blank?
            dsf.update_attributes(failed_at: Time.now, error: response[:error])
          end
        rescue => e
          Rails.logger.error "   FAILED: #{e.message}"
        end
      else
        Rails.logger.error "   Data file #{args["data_file_id"]} doesn't exist, assuming canceled."
      end
    end
    Rails.logger.error "   Done."
  end

end
