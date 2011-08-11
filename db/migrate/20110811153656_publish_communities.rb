class PublishCommunities < ActiveRecord::Migration
  def self.up
    add_column :communities, :published, :boolean, :default => true
  end

  def self.down
    remove_column :communities, :published
  end
end
