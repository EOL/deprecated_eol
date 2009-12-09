class AddLifedeskStatfieldsToPageStatsTaxa < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"    
  end

  def self.up
    add_column  :page_stats_taxa, :lifedesk_taxa, :integer
    add_column  :page_stats_taxa, :lifedesk_dataobject, :integer
  end

  def self.down
    remove_column   :page_stats_taxa, :lifedesk_taxa
    remove_column   :page_stats_taxa, :lifedesk_dataobject
    
  end
end


