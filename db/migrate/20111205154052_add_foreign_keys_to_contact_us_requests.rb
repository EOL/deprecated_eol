class AddForeignKeysToContactUsRequests < ActiveRecord::Migration
  def self.up
    execute('ALTER TABLE contact_us_requests ADD `topic_area_id` integer default NULL')
  end

  def self.down
    remove_column :contact_us_requests, :topic_area_id
  end
end
