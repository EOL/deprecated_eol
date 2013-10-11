class CreateKnownUris < ActiveRecord::Migration
  def change
    create_table :known_uris do |t|
      # limit = http://stackoverflow.com/questions/417142/what-is-the-maximum-length-of-a-url-in-different-browsers
      t.string :uri, null: false, limit: 2000
      t.integer :vetted_id, null: false
      t.integer :visibility_id, null: false
      t.timestamps
    end
    create_table :translated_known_uris do |t|
      t.integer :known_uri_id, null: false
      t.integer :language_id, null: false
      t.string :name, null: false, limit: 128
    end
    add_index :translated_known_uris, [:known_uri_id, :language_id], :unique => true, :name => 'by_language'
  end
end
