class CreateSolrActivityLog < ActiveRecord::Migration
  def self.up
    create_table :solr_activity_logs do |t|
      t.integer :solr_log_id
      t.string :activity_log_unique_key
      t.string :activity_log_type
      t.string :activity_log_id
      t.string :action_keyword
      t.integer :reply_to_id
      t.integer :user_id
      t.datetime :date_created     
    end    
  end

  def self.down
    drop_table :solr_activity_logs
  end
end
