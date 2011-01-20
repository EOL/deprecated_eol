# Represents the connection to the Logging "master" database (where writes are directed)
class LoggingWriter < ActiveRecord::Base
 
  self.abstract_class = true
  
  establish_master_connection :logging

end
