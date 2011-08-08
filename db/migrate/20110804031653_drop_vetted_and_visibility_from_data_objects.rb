class DropVettedAndVisibilityFromDataObjects < ActiveRecord::Migration
  def self.up
    # remove_column :data_objects, :visibility_id
    # remove_column :data_objects, :vetted_id
  end

  def self.down
    # add_column :data_objects, :vetted_id, :integer
    # add_column :data_objects, :visibility_id, :integer
  end
end