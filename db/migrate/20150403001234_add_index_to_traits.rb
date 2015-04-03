class AddIndexToTraits < ActiveRecord::Migration
  def change
    # This took 15 minutes on bocce, which had a table half the size of
    # production. :|
    add_index :traits, :taxon_concept_id
  end
end
