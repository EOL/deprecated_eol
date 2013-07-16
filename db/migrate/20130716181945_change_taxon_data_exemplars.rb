class ChangeTaxonDataExemplars < ActiveRecord::Migration
  def up
    remove_column :taxon_data_exemplars, :parent_type
    rename_column :taxon_data_exemplars, :parent_id, :data_point_uri_id
  end

  def down
    add_column :taxon_data_exemplars, :parent_type, :string, :limit => 64
    rename_column :taxon_data_exemplars, :data_point_uri_id, :parent_id
  end

end
