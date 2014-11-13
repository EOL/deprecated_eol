class CreateImageSizes < ActiveRecord::Migration
  def change
    create_table :image_sizes do |t|
      t.integer :data_object_id
      t.integer :height
      t.integer :width
      t.decimal :crop_x_pct, precision: 5, scale: 2
      t.decimal :crop_y_pct, precision: 5, scale: 2
      t.decimal :crop_width_pct, precision: 5, scale: 2
      t.decimal :crop_height_pct, precision: 5, scale: 2

      t.timestamps
    end
    add_index :image_sizes, :data_object_id
  end
end
