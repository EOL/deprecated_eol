# DO NOT USE THIS unless you know you want your logging to be eager-saved. In general, you probably want to use
# LazyLoggingModel instead.
class LoggingModel < ActiveRecord::Base
  self.abstract_class = true
  octopus_establish_connection("#{Rails.env}_logging")
end
