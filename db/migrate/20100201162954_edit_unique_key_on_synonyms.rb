class EditUniqueKeyOnSynonyms < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute 'DROP INDEX unique_names ON synonyms'
    execute 'ALTER TABLE synonyms ADD UNIQUE KEY `unique_names` (`name_id`,`synonym_relation_id`,`language_id`,`hierarchy_entry_id`, `hierarchy_id`)'
  end
  
  def self.down
    execute 'DROP INDEX unique_names ON synonyms'
    execute 'ALTER TABLE synonyms ADD UNIQUE KEY `unique_names` (`name_id`,`synonym_relation_id`,`language_id`,`hierarchy_entry_id`)'
  end
end
