# If you inherit this, you should probably make sure Comments are set up to use you.  You should also implement a
# #summary_name method (usually an alias to something you already implemented).
module EOL
  module ActivityLoggable
    def activity_log(options = {})
      @activity_log_cache ||= EOL::ActivityLog.find(self, options)
    end
    def reload(*args)
      @activity_log_cache = nil
      super args
    end
  end
end
