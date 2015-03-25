class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.integer :data_object_id
      t.string :guid
      t.string :title
      t.string :language, limit: 8
      t.string :license
      t.string :rights
      t.string :rights_holder
      t.text :body_html
      t.integer :ratings_1
      t.integer :ratings_2
      t.integer :ratings_3
      t.integer :ratings_4
      t.integer :ratings_5
      t.decimal :rating_weighted_average, precision: 3, scale: 2
      t.timestamps
    end
  end
end
