class AddIndexToTraits < ActiveRecord::Migration
  def change
    add_index :traits, :taxon_concept_id
  end
end
