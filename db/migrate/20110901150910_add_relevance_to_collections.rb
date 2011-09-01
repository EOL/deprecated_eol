class AddRelevanceToCollections < ActiveRecord::Migration
  def self.up
    add_column :collections, :relevance, :tinyint, :default => 1
  end

  def self.down
    remove_column :collections, :relevance
  end
end
