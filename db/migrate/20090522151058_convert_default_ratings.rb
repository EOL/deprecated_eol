class ConvertDefaultRatings < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute('update data_objects set data_rating=2.5 where data_rating=0.0;')
  end

  def self.down
    #not worrying about this, we don't want change it to 0 again (and there is no 2.5 rating in `eol_data_integration`.`data_objects` at the moment)
  end
end
