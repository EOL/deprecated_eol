# If you inherit this, you should probably make sure Comments are set up to use you.  You should also implement a
# #summary_name method (usually an alias to something you already implemented).
module EOL
  module ActivityLoggable
    def activity_log(options = {})
      @saved_activity_logs_from_options ||= {}
      h = options.hash
      return @saved_activity_logs_from_options[h] if @saved_activity_logs_from_options.has_key?(h)
      # TODO - why is the dup here? There's no reason for it here; it should be in #find if needed.
      @saved_activity_logs_from_options[h] = EOL::ActivityLog.find(self, options.dup)
    end
  end
end
