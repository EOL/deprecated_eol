class CreateFlatEntries < ActiveRecord::Migration
  def change
    create_table :flat_entries, primary_key: false do |t|
      t.integer :hierarchy_id, null: false
      t.integer :hierarchy_entry_id, null: false
      t.integer :ancestor_id, null: false
    end
    add_index :flat_entries, :hierarchy_id
    add_index :flat_entries, :hierarchy_entry_id
    add_index :flat_entries, :ancestor_id
  end
end
