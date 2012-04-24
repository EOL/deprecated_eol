class FixSerbianIsoCodes < ActiveRecord::Migration
  def self.up
    serbians = Language.find_all_by_iso_639_1('sr', :order => 'id')
    if serbians.length == 2
      serbians.last.iso_639_1 = 'sr-EC'
      serbians.last.save
      User.connection.execute "UPDATE users SET language_id=#{serbians.first.id} WHERE language_id=#{serbians.last.id}"
    end
  end

  def self.down
    execute "UPDATE languages SET iso_639_1 = 'sr' WHERE iso_639_1 = 'sr-EC'"
  end
end
