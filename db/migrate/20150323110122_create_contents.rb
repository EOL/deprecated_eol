class CreateContents < ActiveRecord::Migration
  def change
    create_table :contents do |t|
      t.integer :taxon_concept_id, null: false
      t.string :to_type, null: false
      t.integer :to_id, null: false
      t.string :scientific_name
      t.boolean :trusted, default: false
      t.boolean :hidden, default: false
      t.boolean :exemplar, default: false
      t.integer :user_id # When it was created by a user/curator
      t.integer :hierarchy_entry_id
      t.timestamps
    end
    add_index :contents, :taxon_concept_id
    add_index :contents, [:to_id, :to_type]
  end
end
