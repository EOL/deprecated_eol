class AddMoreFieldsToHeStats < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute('alter table hierarchy_entry_stats add `have_text` mediumint unsigned NOT NULL after `all_text_untrusted`')
    execute('alter table hierarchy_entry_stats add `have_images` mediumint unsigned NOT NULL after `all_image_untrusted`')
  end
  
  def self.down
    remove_column :hierarchy_entry_stats, :have_text
    remove_column :hierarchy_entry_stats, :have_images
  end
end
