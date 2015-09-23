class AddIndexToHierarchyEntries < ActiveRecord::Migration
  def change
    add_index(:hierarchy_entries, [:hierarchy_id, :taxon_concept_id])
  end
end
