# this model represents the connection to the master data database
class SpeciesSchemaWriter < ActiveRecord::Base
  
  self.abstract_class = true
  establish_master_connection :data
  
end
