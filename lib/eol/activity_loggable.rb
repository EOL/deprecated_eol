# If you inherit this, you should probably make sure Comments are set up to use you.  You should also implement a
# #summary_name method (usually an alias to something you already implemented).
module EOL
  module ActivityLoggable
    def activity_log(options = {})
      EOL::ActivityLog.find(self, options)
    end
  end
end
