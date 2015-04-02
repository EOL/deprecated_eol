class AddStringsToHierarchyEntries < ActiveRecord::Migration
  def change
    add_column :hierarchy_entries, :scientific_name, :string
    add_column :hierarchy_entries, :canonical_name, :string
    # Not in title of migration, sorry:
    add_column :hierarchy_entries, :ancestry, :string # pipe-delimited list
    add_column :hierarchy_entries, :species_or_sub, :boolean # pipe-delimited list
  end
end
