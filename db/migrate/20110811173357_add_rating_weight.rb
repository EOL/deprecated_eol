class AddRatingWeight < ActiveRecord::Migration
  def self.up
    add_column :curator_levels, :rating_weight, :integer, :default => 1
  end

  def self.down
    remove_column :curator_levels, :rating_weight
  end
end
