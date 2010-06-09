# This abstract model represents the database connection to the species data slave database
# Models that use this database connection subclass this class    
class SpeciesSchemaModel < ActiveRecord::Base
    self.abstract_class = true
    establish_connection configurations[RAILS_ENV + '_data']
end
