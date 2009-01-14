class SpeciesSchemaWriter < ActiveRecord::Base
  
  # this model represents the connection to the master data database
  
  self.abstract_class = true
  
  establish_connection :master_data_database
  
end