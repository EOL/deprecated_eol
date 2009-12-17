class ChangeRefsStringToText < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    remove_index :refs, :name => 'full_reference'
    execute('alter table refs modify `full_reference` text NOT NULL')
    execute('create index full_reference on refs (full_reference(200))')
    execute("alter table refs add `visibility_id` tinyint unsigned NOT NULL default 0")
    execute("alter table refs add `published` tinyint unsigned NOT NULL default 0")
    
  end
  
  def self.down
    remove_index :refs, :name => 'full_reference'
    execute('alter table refs modify `full_reference` varchar(400) NOT NULL')
    execute('create index full_reference on refs (full_reference)')
    remove_column :refs, :visibility_id
    remove_column :refs, :published
  end
end
