class FixUserExpertiseValues < ActiveRecord::Migration
  def self.up
    #two users seem to have the string "middle\n", one of them being remi2, created in january
    execute('update users set expertise="middle" where expertise="middle\n";')

    #there were no users with their expertise set to "--- :novice\n", not sure why, but maybe that's a clue to what caused this bad data

    #there were 65 users with their expertise set to "--- :middle\n"
    execute('update users set expertise="middle" where expertise="--- :middle\n";')

    #there were 41 users with their expertise set to "--- :expert\n"
    execute('update users set expertise="expert" where expertise="--- :expert\n";')
  end

  def self.down
    #not worrying about this... since there's no use for it and it's not really fesible
  end
end
