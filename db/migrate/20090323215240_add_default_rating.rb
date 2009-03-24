class AddDefaultRating < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    change_column :data_objects, :data_rating, :float, :default => 0
  end

  def self.down
    change_column :data_objects, :data_rating, :float
  end
end
