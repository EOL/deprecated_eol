class AddTaxonConceptIndexToDataPointUris < ActiveRecord::Migration
  def change
    add_index :data_point_uris, :taxon_concept_id
  end
end
