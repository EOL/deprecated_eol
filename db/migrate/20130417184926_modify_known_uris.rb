class ModifyKnownUris < ActiveRecord::Migration

  def up
    create_table :known_uris_toc_items do |t|
      t.integer :known_uri_id, null: false
      t.integer :toc_item_id, null: false
    end
    KnownUri.connection.execute("CREATE UNIQUE INDEX `by_uri` ON `known_uris` (uri(250))")
  end

  def down
    drop_table :known_uris_toc_items
    remove_index :known_uris, name: 'by_uri'
  end

end
