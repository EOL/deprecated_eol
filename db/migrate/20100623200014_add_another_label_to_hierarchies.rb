class AddAnotherLabelToHierarchies < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute('alter table hierarchies add `descriptive_label` varchar(255) NULL after `label`')
  end
  
  def self.down
    remove_column :hierarchies, :descriptive_label
  end
end
