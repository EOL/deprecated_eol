class AddTimeOnPagesToGoogleAnalyticsSummaries < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    add_column :google_analytics_summaries, :time_on_pages, :integer
    execute"RENAME TABLE google_analytics_page_stat TO google_analytics_page_stats;"
  end

  def self.down
    remove_column :google_analytics_summaries, :time_on_pages
    execute"RENAME TABLE google_analytics_page_stats TO google_analytics_page_stat;"
  end
end
