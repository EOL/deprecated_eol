class RenameUnknownToUnreviewed < ActiveRecord::Migration
  def self.up
    execute("update translated_vetted set label='Unreviewed' where label='Unknown'")
  end

  def self.down
    execute("update translated_vetted set label='Unknown' where label='Unreviewed'")
  end
end