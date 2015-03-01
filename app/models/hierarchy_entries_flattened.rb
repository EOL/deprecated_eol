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
    with_master do
      big = entry.number_of_descendants > 1000
      begin
        create_tmp if big
        delete_all(["ancestor_id = ?", entry.id]) unless big
        connection.execute(
          "INSERT INTO #{big ? tmp_table : table_name} "\
          "(hierarchy_entry_id, ancestor_id) "\
          "SELECT hierarchy_entries.id, #{entry.id} "\
          "FROM hierarchy_entries "\
          "WHERE lft BETWEEN #{entry.lft} + 1 AND #{entry.rgt} AND "\
          "hierarchy_id = #{entry.hierarchy_id}")
        if big
          delete_all(["ancestor_id = ?", entry.id])
          connection.execute(
            "INSERT IGNORE INTO hierarchy_entries_flattened "\
            "(hierarchy_entry_id, ancestor_id) "\
            "SELECT hierarchy_entry_id, ancestor_id "\
            "FROM #{tmp_table}"
          )
        end
        ensure
          if big
            drop_tmp
            # This is a VERY expensive process; I'm just allowing a
            # little breathing room. If it has 150,000 descendants, it will pause
            # for 15 seconds.
            time = entry.number_of_descendants / 10000.0
            time = 1 if time.to_i == 0
            sleep(time)
          end
        end
    end
  end

  # A TEMPORARY table is visible only to the current session, and is dropped
  # automatically when the session is closed. This means that two different
  # sessions can use the same temporary table name without conflicting with each
  # other or with an existing non-TEMPORARY table of the same name.
  # http://dev.mysql.com/doc/refman/5.1/en/create-table.html
  def self.tmp_table
    "TEMP_hierarchy_entries_flattened"
  end

  def self.create_tmp
    drop_tmp
    connection.execute("CREATE TEMPORARY TABLE #{tmp_table} "\
      "SELECT * FROM #{table_name} WHERE 1=0")
  end

  def self.drop_tmp
    connection.execute("DROP TEMPORARY TABLE IF EXISTS #{tmp_table}")
  end
  
end
