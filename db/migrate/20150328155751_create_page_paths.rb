class CreateAncestorPage < ActiveRecord::Migration
  def change
    create_table :page_paths, id: false do |t|
     t.integer :ancestor_id
     t.integer :descendant_id
    end
    add_index :ancestor_pages, [:ancestor_id, :descendant_id], name: "pk", unique: true
    add_index :ancestor_pages, :ancestor_id
    add_index :ancestor_pages, :descendant_id
  end
end
