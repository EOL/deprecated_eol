class CreateFlatTaxa < ActiveRecord::Migration
  def change
    create_table :flat_taxa, primary_key: false do |t|
      t.integer :hierarchy_id, null: false
      t.integer :hierarchy_entry_id, null: false
      t.integer :taxon_concept_id, null: false
      t.integer :ancestor_id, null: false
    end
    add_index :flat_taxa, :hierarchy_id
    add_index :flat_taxa, :hierarchy_entry_id
    add_index :flat_taxa, :ancestor_id
  end
end
