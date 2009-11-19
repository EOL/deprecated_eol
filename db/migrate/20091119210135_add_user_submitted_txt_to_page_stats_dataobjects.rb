class AddUserSubmittedTxtToPageStatsDataobjects < ActiveRecord::Migration
  def self.up
    add_column  :page_stats_dataobjects, :user_submitted_text, :integer
  end
  
  def self.down
    remove_column   :page_stats_dataobjects, :user_submitted_text
  end
end
