class CreateTableCollectionFromListMatches < ActiveRecord::Migration
  def up
    create_table :collection_from_list_matches do |t|
      t.integer :string_id
      t.integer :taxon_concept_id
      t.timestamps
    end
  end

  def down
    drop_table :collection_from_list_matches
  end
end
