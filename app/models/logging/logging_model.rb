# The abstract base class for all models requiring a connection to the logging database.
#
# Author: Preston Lee <preston.lee@openrain.com>
class LoggingModel < ActiveRecord::Base
 
  self.abstract_class = true
  
  # The connections for the logging database are defined in the "config/database.yml" file, and 
  # are all suffixed with "_logging" (development_logging, test_logging, etc)    
  use_db :suffix =>  '_logging'

end