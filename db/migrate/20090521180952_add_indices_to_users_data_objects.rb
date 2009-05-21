class AddIndicesToUsersDataObjects < ActiveRecord::Migration
  def self.up
    add_index :users_data_objects, :data_object_id
    add_index :users_data_objects, :taxon_concept_id
  end

  def self.down
    remove_index :users_data_objects, :taxon_concept_id
    remove_index :users_data_objects, :data_object_id
  end
end
