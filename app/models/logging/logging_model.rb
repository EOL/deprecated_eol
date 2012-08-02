# DO NOT USE THIS unless you know you want your logging to be eager-saved. In general, you probably want to use
# LazyLoggingModel instead.
class LoggingModel < ActiveRecord::Base

  self.abstract_class = true

  if $LOGGING_READ_FROM_MASTER
    # if configured to do so, ALWAYS read and write from master DB for logging classes
    establish_master_connection :logging
  else
    establish_connection configurations["#{Rails.env}_logging"]
  end

end
