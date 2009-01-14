class SpeciesSchemaModel < ActiveRecord::Base

    # This abstract model represents the database connection to the species data slave database
    # Models that use this database connection subclass this class    
    self.abstract_class = true
    
    # Database connections for the species database are defined in the "config/database.yml" file, and are all suffixed with "_data" after the environment    
    use_db :suffix =>  '_data'
    
end
