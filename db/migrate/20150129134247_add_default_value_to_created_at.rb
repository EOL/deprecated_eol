class AddDefaultValueToCreatedAt < ActiveRecord::Migration
  def change
    change_column :image_sizes, :created_at, :datetime, :null => false, :default => CURRENT_TIMESTAMP
  end
end
