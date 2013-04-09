class ChangeUserAddedData < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE user_added_data ADD subject_type varchar(255) NOT NULL AFTER user_id"
    execute "ALTER TABLE user_added_data ADD subject_id int(11) NOT NULL AFTER subject_type"
    remove_column :user_added_data, :subject
  end

  def self.down
    remove_column :user_added_data, :subject_type
    remove_column :user_added_data, :subject_id
    execute "ALTER TABLE user_added_data ADD subject varchar(255) NOT NULL AFTER user_id"
  end
end
