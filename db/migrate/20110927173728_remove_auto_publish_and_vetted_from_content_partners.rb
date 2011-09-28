class RemoveAutoPublishAndVettedFromContentPartners < ActiveRecord::Migration
  def self.up
    remove_column :content_partners, :auto_publish
    remove_column :content_partners, :vetted
  end

  def self.down
    add_column :content_partners, :auto_publish, :boolean, :default => 0, :null => false
    add_column :content_partners, :vetted, :boolean, :default => 0, :null => false
  end
end
