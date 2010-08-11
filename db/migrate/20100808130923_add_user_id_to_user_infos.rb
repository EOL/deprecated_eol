class AddUserIdToUserInfos < ActiveRecord::Migration
  def self.up
    add_column :user_infos, :user_id, :integer
  end

  def self.down
    remove_column :user_infos, :user_id, :integer
  end
end
