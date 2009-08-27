class AddHeIndexToTaxa < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  def self.up
    add_index :taxa, :hierarchy_entry_id
  end
  def self.down
    # Not worth doing
  end
end
