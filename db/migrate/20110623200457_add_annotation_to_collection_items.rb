class AddAnnotationToCollectionItems < ActiveRecord::Migration
  def self.up
    execute('ALTER TABLE collection_items ADD `annotation` text default NULL')
  end

  def self.down
    remove_column :collection_items, :annotation
  end
end
