# Represents the connection to the Logging "master" database (where writes are directed)
class LoggingWriter < ActiveRecord::Base
 
  self.abstract_class = true
  
  establish_connection :master_logging_database

end
