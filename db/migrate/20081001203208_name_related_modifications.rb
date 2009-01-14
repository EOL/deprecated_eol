class NameRelatedModifications < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up

    execute "CREATE TABLE agents_synonyms (
        synonym_id INT UNSIGNED NOT NULL
       , agent_id INT UNSIGNED NOT NULL
       , agent_role_id TINYINT UNSIGNED NOT NULL
       , view_order TINYINT UNSIGNED NOT NULL
       , PRIMARY KEY (synonym_id, agent_id, agent_role_id)
      ) ENGINE=InnoDB"
    
  end

  def self.down
    drop_table :agents_synonyms
  end
end
