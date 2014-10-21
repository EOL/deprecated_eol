class CreateImageSizes < ActiveRecord::Migration
  def change
    create_table :image_sizes do |t|
      t.integer :data_object_id
      t.integer :height
      t.integer :width
      t.integer :crop_x
      t.integer :crop_y
      t.integer :crop_width
      t.integer :crop_height

      t.timestamps
    end
    add_index :image_sizes, :data_object_id
  end
end
