class RemoveUnneededFieldsInPageStatsTaxa < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    remove_column :page_stats_taxa, :active    
    remove_column :page_stats_taxa, :a_taxa_with_text
    remove_column :page_stats_taxa, :a_vetted_not_published
    remove_column :page_stats_taxa, :a_vetted_unknown_published_visible_notinCol
    remove_column :page_stats_taxa, :a_vetted_unknown_published_visible_inCol
    remove_column :page_stats_taxa, :date_created
    remove_column :page_stats_taxa, :time_created
    rename_column :page_stats_taxa, :timestamp, :date_created    
  end

  def self.down
    rename_column :page_stats_taxa, :date_created, :timestamp    
    add_column :page_stats_taxa, :active, :string, :limit => 1    
    add_column :page_stats_taxa, :date_created, :date
    add_column :page_stats_taxa, :time_created, :time    
    
    execute "ALTER TABLE page_stats_taxa 
        ADD COLUMN a_taxa_with_text                             LONGTEXT,
        ADD COLUMN a_vetted_not_published                       LONGTEXT,
        ADD COLUMN a_vetted_unknown_published_visible_notinCol  LONGTEXT,
        ADD COLUMN a_vetted_unknown_published_visible_inCol     LONGTEXT
    "
  end

end
