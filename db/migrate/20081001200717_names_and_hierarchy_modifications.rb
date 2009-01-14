class NamesAndHierarchyModifications < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute "ALTER TABLE hierarchy_entries ADD COLUMN identifier VARCHAR(20) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL AFTER id" 
    execute "ALTER TABLE agents_hierarchy_entries DROP PRIMARY KEY"
    execute "ALTER TABLE agents_hierarchy_entries ADD PRIMARY KEY (hierarchy_entry_id, agent_id, agent_role_id)"
    execute "CREATE INDEX vern ON taxon_concept_names (vern)"
    
    execute "CREATE TABLE clean_names (
      name_id INT UNSIGNED NOT NULL
     , clean_name VARCHAR(300) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL
     , PRIMARY KEY (name_id)
     , INDEX (clean_name)
    ) ENGINE = InnoDB"
    
  end

  def self.down
    drop_table :clean_names
    remove_index :taxon_concept_names, :name=>'vern'
    execute "ALTER TABLE agents_hierarchy_entries DROP PRIMARY KEY"
    execute "ALTER TABLE agents_hierarchy_entries ADD PRIMARY KEY (hierarchy_entry_id, agent_id)"
    remove_column :hierarchy_entries, :identifier
  end
end
