class AlterTaxonDataExemplars < ActiveRecord::Migration
  def change
    add_column :taxon_data_exemplars, :exclude, :boolean, :default => 0, :null => false
    add_column :known_uris, :exclude_from_exemplars, :boolean, :default => 0, :null => false
  end
end
