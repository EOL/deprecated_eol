class AddTcIdToUserText < ActiveRecord::Migration
  def self.up
    add_column :users_data_objects, :taxon_concept_id, :integer
  end

  def self.down
    remove_column :users_data_objects, :taxon_concept_id
  end
end
