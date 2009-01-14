class AddTagsSearchLog < ActiveRecord::Migration
  def self.database_model
    return "LoggingModel"
  end
  
  def self.up
    add_column :search_logs, :number_of_tag_results, :integer
  end

  def self.down
    remove_column :search_logs, :number_of_tag_results
  end
end