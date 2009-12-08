class AddIndicesToLangauges < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute("create index iso_639_1 on languages(iso_639_1)")
    execute("create index iso_639_2 on languages(iso_639_2)")
    execute("create index iso_639_3 on languages(iso_639_3)")
  end
  
  def self.down
    remove_index :languages, :name => 'iso_639_1'
    remove_index :languages, :name => 'iso_639_2'
    remove_index :languages, :name => 'iso_639_3'
  end
end
