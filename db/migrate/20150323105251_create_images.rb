class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.integer :data_object_id
      t.string :guid
      t.string :cache_id
      t.string :title
      t.string :source_url
      t.timestamps
    end
    add_index :images, :data_object_id, unique: true
    add_index :images, :guid
  end
end
