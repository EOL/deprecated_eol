class AddSpmStatsFieldsInPageStatsTaxa < EOL::DataMigration
  def self.up
    add_column :page_stats_taxa, :data_objects_count_per_category, :text
    add_column :page_stats_taxa, :content_partners_count_per_category, :text
  end

  def self.down
    remove_column :page_stats_taxa, :data_objects_count_per_category
    remove_column :page_stats_taxa, :content_partners_count_per_category
  end
end



