class CreateSolrLog < ActiveRecord::Migration
  def self.up
    create_table :solr_logs do |t|
      t.string :core, :limit => 128
      t.string :action, :limit => 128
      t.string :object_id
      t.string :object_type
      t.integer :peer_site_id
      t.timestamps    
    end    
  end

  def self.down
    drop_table :solr_logs
  end
end