class AddUnitToDataSearchFile < ActiveRecord::Migration

  def up
    add_column :data_search_files, :unit_uri, :string, null: true
    add_column :data_search_files, :taxon_concept_id, 'integer unsigned', null: true
    change_column :data_search_files, :from, :float
    change_column :data_search_files, :to, :float
  end

  def down
    remove_column :data_search_files, :unit_uri
    remove_column :data_search_files, :taxon_concept_id
    change_column :data_search_files, :from, :string
    change_column :data_search_files, :to, :string
  end

end
