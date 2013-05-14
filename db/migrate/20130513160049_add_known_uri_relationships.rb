class AddKnownUriRelationships < ActiveRecord::Migration
  def change
    create_table :known_uri_relationships do |t|
      t.integer :from_known_uri_id, null: false
      t.integer :to_known_uri_id, null: false
      t.string :relationship_uri, null: false
      t.timestamps
    end
    add_index :known_uri_relationships, [ :from_known_uri_id, :to_known_uri_id, :relationship_uri ], :unique => true, :name => 'from_to_unique'
    add_index :known_uri_relationships, :to_known_uri_id, :name => 'to_known_uri_id'
  end
end
