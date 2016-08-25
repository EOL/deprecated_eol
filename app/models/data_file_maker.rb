class DataFileMaker

  @queue = 'data'

  # TODO - logging here is bad; improve. I'm using #error just to ensure it shows up in the log, but that's probably subprime.
  def self.perform(args)
    EOL.log_call
    # Once upon a time, a job was skipped because it didn't exist... but it should have.
    # I assume this was a case of slight slave lag and bad timing, so to ensure
    # that doesn't cause a problem:
    DataSearchFile.with_master do
      if DataSearchFile.exists?(args["data_file_id"])
        begin
          dsf = DataSearchFile.find(args["data_file_id"])
          move_user_files_to_bottom(dsf.id)
          EOL.log("DataSearchFile ##{dsf.id} for user #{dsf.user.full_name} (#{dsf.user_id})", prefix: ".")
          dsf.build_file
        rescue => e
          EOL.log_error(e)
        end
      else
        EOL.log("ID #{args["data_file_id"]} doesn't exist, canceled?",
          prefix: ".")
      end
    end
    EOL.log("Done #{args["data_file_id"]}.", prefix: ".")
  end

  private
    def self.move_user_files_to_bottom(data_file_id)
      user_id = DataSearchFile.find(data_file_id).user_id rescue nil
      if user_id
        user_pending_files_ids = DataSearchFile.where(user_id: user_id).pending.pluck(:id)
        user_pending_files_ids.each do |file_id|
          found = Resque.dequeue(DataFileMaker,data_file_id: file_id)
          Resque.enqueue(DataFileMaker,data_file_id: file_id) unless found.zero?
        end
      end
    end
end
