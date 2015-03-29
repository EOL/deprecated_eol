class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.integer :parent_id, null: false
      t.integer :taxon_concept_id, null: false
      t.integer :source_id, null: false
      t.string :scientific_name, null: false
      t.string :resource_key
      t.string :url
      # Intended to be I18n'ed by hash key (or shown as English):
      t.string :rank, default: "Taxon"
      t.boolean :exemplar, default: false
      t.boolean :species_or_sub, default: false # Determines use of italics
    end
    add_index :nodes, :hierarchy_entry_id
    add_index :nodes, :taxon_concept_id
  end
end
