class CreateConceptsHierarchies < ActiveRecord::Migration
  def change
    create_table :concepts_hierarchies, id: false do |t|
      t.integer :ancestor_id, null: false
      t.integer :descendant_id, null: false
      t.integer :generations, null: false
    end
    add_index :concepts_hierarchies,
      [:ancestor_id, :descendant_id, :generations],
      unique: true, name: "concepts_anc_desc_udx"
    add_index :concepts_hierarchies, [:descendant_id], name: "concepts_desc_idx"
  end
end
