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
