# An ancestry tree for hierarchy entries. It's a bit absurd to me that
# hierarchy_id isn't in the fields. It's also crazy that we don't index
# individual fields (just the PK, which is the combo)... but so far, things
# aren't _that_ slow, so we perservere.
class HierarchyEntriesFlattened < ActiveRecord::Base
  self.table_name = "hierarchy_entries_flattened"
  self.primary_keys = :hierarchy_entry_id, :ancestor_id

  belongs_to :hierarchy_entry, class_name: HierarchyEntry.to_s, foreign_key: :hierarchy_entry_id
  belongs_to :ancestor, class_name: HierarchyEntry.to_s, foreign_key: :ancestor_id

  # NOTE: This is very, very, VERY slow. It's using the PK, so that's not the
  # problem... It's just that deletes are very slow. Don't call this. Seriously.
  # You probably want to create a diff and delete only the things you need to.
  def self.delete_hierarchy_id(hierarchy_id)
    EOL.log_call
    ids = in_hierarchy(hierarchy_id).
      map { |r| "(#{r.hierarchy_entry_id}, #{r.ancestor_id})" }
    return if ids.empty?
    ids.in_groups_of(6400, false) do |set|
      delete_set(set)
    end
  end

  def self.delete_set(group)
    return if group.empty?
    where("(hierarchy_entry_id, ancestor_id) IN (#{group.to_a.join(",")})").
      delete_all
  end

  def self.pks_in_hierarchy(hierarchy)
    EOL.log_call
    pks = Set.new
    ids = hierarchy.hierarchy_entries.pluck(:id)
    num = 0
    ids.in_groups_of(10_000).each do |group|
      EOL.log("Group #{num += 1} (#{group.size})") if ids.size > 10_000
      # NOTE: This was going REALLY (!!!) slow, so I am skipping it for now:
      # pks += EOL.pluck_pks(self, where(hierarchy_entry_id: group))
      pks += where(hierarchy_entry_id: group).map do |hef|
        "#{hef.hierarchy_entry_id},#{hef.ancestor_id}"
      end
    end
    pks
  end

  # scope :in_hierarchy, ->(hierarchy_id) { where("(hierarchy_entry_id, "\
  #   "ancestor_id) IN (#{in_hierarchy_pks(hierarchy_id).to_sql})") }
    # where("product_id IN (#{select("product_id").joins(:artist).where("artist.is_disabled = TRUE").to_sql})")

  # NOTE: this does NOT "cascade": all of these descendants will be aware of
  # THIS node, but NOT about all interceding nodes. i.e., if you run this on
  # "Animalia", then "Carnivora" will know "Animalia" is an ancestor, and
  # "Procyon" will know that "Animalia" is an ancestor, but THIS command will
  # NOT make "Procyon" know that "Carnivora" is an ancestor!  You have been
  # warned. On the positive side, this command is actually pretty dern fast, all
  # things considered. ...Had to use raw SQL here, though, to get the
  # performance. :\
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

  # TODO: This should really be an aliased attribute (I think), but I'm in a rush.
  def flat_ancestor
    ancestor
  end
end
