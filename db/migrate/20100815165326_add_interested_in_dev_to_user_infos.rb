class AddInterestedInDevToUserInfos < ActiveRecord::Migration
  def self.up
    add_column :user_infos, :interested_in_development, :boolean
  end

  def self.down
    remove_column :user_infos, :interested_in_development
  end
end
