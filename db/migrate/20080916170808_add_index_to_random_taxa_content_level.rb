class AddIndexToRandomTaxaContentLevel < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    add_index :random_taxa, :content_level
  end

  def self.down
    remove_index :random_taxa, :content_level
  end

end
