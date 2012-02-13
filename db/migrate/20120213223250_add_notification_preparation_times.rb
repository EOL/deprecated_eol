class AddNotificationPreparationTimes < ActiveRecord::Migration

  def self.up
    add_column :comments, :notifications_prepared_at, :datetime
    Comment.connection.execute("UPDATE comments SET notifications_prepared_at = '#{Time.now}'")
    add_column :users_data_objects, :notifications_prepared_at, :datetime
    UsersDataObject.connection.execute("UPDATE #{UsersDataObject.table_name} SET notifications_prepared_at = '#{Time.now}'")
  end

  def self.down
    remove_column :users_data_objects, :notifications_prepared_at
    remove_column :comments, :notifications_prepared_at
  end

end
