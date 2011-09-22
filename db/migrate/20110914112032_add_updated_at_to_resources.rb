class AddUpdatedAtToResources < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE `resources` ADD `updated_at` timestamp NULL DEFAULT NULL")
  end

  def self.down
    remove_column :resources, :updated_at
  end
end
