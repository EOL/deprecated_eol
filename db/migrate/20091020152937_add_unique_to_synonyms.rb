class AddUniqueToSynonyms < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute("ALTER IGNORE TABLE synonyms ADD UNIQUE INDEX unique_names (name_id, synonym_relation_id, language_id, hierarchy_entry_id)");
  end
  
  def self.down
    execute("DROP INDEX unique_names ON synonyms");
  end
end
