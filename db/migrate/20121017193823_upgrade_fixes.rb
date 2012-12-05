class UpgradeFixes < ActiveRecord::Migration
  def up
    # Invalid date in the users table:
    User.connection.execute("update users set last_report_email = '2011-09-01 00:00:00' " +
                            "where last_report_email = '2011-09-00 00:00:00';")
  end

  def down
    # Nothing to do.
  end
end
