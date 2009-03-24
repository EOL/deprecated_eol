# this model represents the connection to the master data database
class SpeciesSchemaWriter < ActiveRecord::Base
  
  self.abstract_class = true
  
  establish_connection :master_data_database
  
end
