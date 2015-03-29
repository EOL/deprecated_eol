class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.integer :data_object_id
      t.string :guid
      t.string :cache_id
      t.string :source_url
      t.string :title
      t.string :pages_in_media
      t.string :language, limit: 8
      t.string :license
      t.string :rights
      t.string :rights_holder
      t.integer :ratings_1
      t.integer :ratings_2
      t.integer :ratings_3
      t.integer :ratings_4
      t.integer :ratings_5
      t.decimal :rating_weighted_average, precision: 3, scale: 2
      t.timestamps
    end
    add_index :images, :data_object_id, unique: true
    add_index :images, :guid
    add_index :images, :language
  end
end
