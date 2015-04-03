class AddStringsToHierarchyEntries < ActiveRecord::Migration
  def up
    # What we're doing in Rails terms:
    if HierarchyEntry.connection.config[:adapter] == "mysql2"
      # This is (nearly) 3x faster, since we do them all at once, and in our
      # environment, this still takes a LOOOOONG time (like, go to breakfast, man)...
      # The first one took 4670411.2ms on bocce!
      HierarchyEntry.connection.execute(
        "ALTER TABLE hierarchy_entries "\
        "ADD COLUMN scientific_name VARCHAR(255) DEFAULT '', "\
        "ADD COLUMN canonical_name VARCHAR(255) DEFAULT '', "\
        "ADD COLUMN species_or_sub TINYINT(1) DEFAULT 0"
      )
    else # For other database drivers (YEAH RIGHT, HAHAHAHAHAHAHAHA)
      add_column :hierarchy_entries, :scientific_name, :string, default: ""
      add_column :hierarchy_entries, :canonical_name, :string, default: ""
      # Not in title of migration, sorry:
      add_column :hierarchy_entries, :species_or_sub, :boolean, default: false
    end
  end

  def down
    remove_column :hierarchy_entries, :scientific_name
    remove_column :hierarchy_entries, :canonical_name
    remove_column :hierarchy_entries, :species_or_sub
  end
end
