class CreateDataSearchFiles < ActiveRecord::Migration
  def change
    create_table :data_search_files do |t|
      t.string :q, limit: 512, null: false
      t.string :uri, limit: 512, null: false # TODO - this might change.
      t.string :from, limit: 64
      t.string :to, limit: 64
      t.string :sort, limit: 64
      t.integer :user_id
      t.integer :known_uri_id, null: false # TODO - this might change.
      t.integer :language_id
      t.timestamps
    end
    add_index :data_search_files, :user_id
    add_index :data_search_files, :known_uri_id
  end
end
