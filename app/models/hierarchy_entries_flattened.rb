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

  # TODO: remove these comments. Sorry! I just wanted them in a portable place.

  # Trouble with: 54996767 (0 descendants?)
  # > /home/jrice/nohup.out ; nohup bundle exec rails runner -e production "a = [61099828, 61190725, 61256847, 61282141, 61287729, 61279826]; a.each { |id| he = HierarchyEntry.find(id) ; puts '+' * 80; puts Time.now ; puts he.id ; puts he.number_of_descendants ; puts '+' * 80 ; STDOUT.flush ; he.repopulate_flattened_hierarchy ; puts 'Done, sleeping.' ; STDOUT.flush } ; puts Time.now ; puts 'DONE-DONE'" &

  # nohup bundle exec rails runner -e production "a = [20625088, 20627409, 20828279, 24808283, 24913771, 24974884, 26323677, 27882936, 27918164, 24876515, 28019018, 28062010, 28391676, 28560571, 30035767, 29190316, 31031322, 32523850, 32641289, 32662668, 32717231, 32756333, 32817177, 32983897, 33058503, 33068847, 33098806, 33101299, 33118890, 33122770, 33189617, 33268078, 33311700, 35291886, 35552110, 35694170, 36236316, 36281787, 28333399, 37223161, 36997724, 37464436, 37470348, 38118765, 38172977, 38200811, 37293282, 38285287, 39227197, 40846487, 41038437, 40973468, 24873337, 44661379]; a.each { |id| he = HierarchyEntry.find(id) ; puts '+' * 80; puts Time.now ; puts he.id ; puts he.number_of_descendants ; puts '+' * 80 ; STDOUT.flush ; he.repopulate_flattened_hierarchy ; puts 'Done.' ; STDOUT.flush } ; puts Time.now ; puts 'DONE-DONE'" &> /home/jrice/nohup2.out&

  # nohup bundle exec rails runner -e production "a = [16103368, 18880282, 44859250, 44861620, 44897125, 45050486, 45127752, 45134847, 45140710, 45713502, 45787482, 45135982, 46150613, 46698131, 46708292, 46711174, 45127013, 46733340, 20571209, 47082756, 47111832, 48704837, 35439615, 48807880, 49072667, 49639305, 49664588, 49674341, 49688786, 49691722, 49727621, 50061498, 50026292, 50124077, 50179865, 50274665, 50375039, 50382890, 50688490, 51414435, 51521761, 53422118, 53601997, 53649972, 53669278, 53698760, 53704309, 53723979, 53727637, 53730382]; a.each { |id| he = HierarchyEntry.find(id) ; puts '+' * 80; puts Time.now ; puts he.id ; puts he.number_of_descendants ; puts '+' * 80 ; STDOUT.flush ; he.repopulate_flattened_hierarchy ; puts 'Done.' ; STDOUT.flush } ; puts Time.now ; puts 'DONE-DONE'" &> /home/jrice/nohup3.out&

end
