class CreateContents < ActiveRecord::Migration
  def change
    create_table :contents do |t|
      t.integer :taxon_concept_id, null: false
      t.integer :data_object_id, null: false
      t.integer :to_id, null: false
      t.string :to_type, null: false
      t.string :scientific_name
      t.boolean :trusted, default: false
      t.boolean :hidden, default: false
      t.boolean :exemplar, default: false
      t.boolean :shown, default: false
      t.boolean :untrusted, default: false
      t.boolean :ancestor, default: false # When this is "inherited" from ancestor page
      t.integer :hierarchy_entry_id
      t.timestamps
    end
    add_index :contents, :taxon_concept_id
    add_index :contents, [:data_object_id, :taxon_concept_id], name: "dot"
    add_index :contents, [:to_id, :to_type]
  end
end
