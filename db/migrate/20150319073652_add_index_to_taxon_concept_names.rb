class AddIndexToTaxonConceptNames < ActiveRecord::Migration
  def change
    add_index :taxon_concept_names, [:taxon_concept_id, :name_id, :source_hierarchy_entry_id,:language_id, :vern, :preferred], name: 'index_for_load_common_names_in_bulk' 
  end
end
