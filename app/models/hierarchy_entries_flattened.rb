class HierarchyEntriesFlattened < ActiveRecord::Base
  self.table_name = "hierarchy_entries_flattened"
  belongs_to :hierarchy_entries
  belongs_to :ancestor, class_name: HierarchyEntry.to_s, foreign_key: :ancestor_id

  # NOTE: this does NOT "cascade": all of these descendants will be aware of
  # THIS node, but NOT about all interceding nodes. i.e., if you run this on
  # "Animalia", then "Carnivora" will know "Animalia" is an ancestor, and
  # "Procyon" will know that "Animalia" is an ancestor, but THIS command will
  # NOT make "Procyon" know that "Carnivora" is an ancestor!  You have been
  # warned.
  # On the positive side, this command is actually pretty dern fast, all things
  # considered. ...Had to use raw SQL here, though, to get the performance. :\
  def self.repopulate(entry)
    HierarchyEntry.connection.execute(
      "INSERT IGNORE INTO hierarchy_entries_flattened "\
      "(hierarchy_entry_id, ancestor_id) "\
      "SELECT hierarchy_entries.id, #{entry.id} "\
      "FROM hierarchy_entries "\
      "WHERE lft BETWEEN #{entry.lft} + 1 AND #{entry.rgt}")
  end
end
