class ConvertRatings < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute('update data_objects set data_rating=(((10000-data_rating)/10000)*5) where data_rating!=0.0;')
  end

  def self.down
    execute('update data_objects set data_rating=(10000-((data_rating/5)*10000)) where data_rating!=0.0;')
  end
end
