class AddInaturalistUrlsToUsersAndCollections < ActiveRecord::Migration
  def self.up
    add_column :users, :inaturalist_username, :string
    add_column :collections, :inaturalist_observations_url, :string
  end

  def self.down
    remove_column :collections, :inaturalist_observations_url
    remove_column :users, :inaturalist_username
  end
end