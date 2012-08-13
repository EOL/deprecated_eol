class RemoveNotificationsWithUserIdZero < ActiveRecord::Migration
  def self.up
    execute("DELETE FROM `notifications` WHERE `user_id`=0")
  end

  def self.down
    # irreversible migration
  end
end
