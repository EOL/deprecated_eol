# This abstract model represents the database connection to the species data slave database
# Models that use this database connection subclass this class.

# We are no longer using separate databases so this superclass is maintained in case we do need
# to revert to the old database (as is the case of migrations), and simply to identify the models
# which used to be separated

class SpeciesSchemaModel < ActiveRecord::Base
    self.abstract_class = true
end
