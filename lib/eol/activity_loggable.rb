# If you inherit this, you should probably make sure Comments are set up to use you.  You should also implement a
# #summary_name method (usually an alias to something you already implemented).
module EOL
  module ActivityLoggable
    def activity_log(options = {})
      EOL::ActivityLog.find(self, options)
    end
    def reload(*args)
      @activity_log_cache = nil
      super args
    end
  end

  module ActivityLogItem
    def log_date
      if self.is_a? UsersDataObject
        if self.data_object.updated_at >= (self.data_object.created_at + 2.minutes)
          return self.data_object.updated_at
        else
          return self.data_object.created_at
        end
      else
        return self.created_at
      end
    end
  end
end
