class MakeCuratorsFull < ActiveRecord::Migration
  def self.up
    CuratorLevel.create_defaults # because it doesn't hurt
    User.connection.execute("UPDATE users SET curator_level_id = #{CuratorLevel.full.id} where curator_approved = 1")
  end

  def self.down
    # Doesn't really matter.
  end
end
