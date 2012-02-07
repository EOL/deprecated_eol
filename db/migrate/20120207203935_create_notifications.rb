class CreateNotifications < ActiveRecord::Migration
  def self.up

    create_table :notification_frequencies do |t|
      t.string :frequency, :limit => 16 # NOTE - I'm not I18n'zing these because it's a lot of work and doesn't add
                                        # much; we'll just reference the string in the code.
    end

    NotificationFrequency.create_defaults

    create_table :notifications do |t|
      t.integer :user_id, :null => false
      t.integer :reply_to_comment, :default => NotificationFrequency.immediately.id
      t.integer :comment_on_my_profile, :default => NotificationFrequency.immediately.id
      t.integer :comment_on_my_contribution, :default => NotificationFrequency.immediately.id
      t.integer :comment_on_my_collection, :default => NotificationFrequency.immediately.id
      t.integer :comment_on_my_community, :default => NotificationFrequency.immediately.id
      t.integer :made_me_a_manager, :default => NotificationFrequency.immediately.id
      t.integer :member_joined_my_community, :default => NotificationFrequency.immediately.id
      t.integer :comment_on_my_watched_item, :default => NotificationFrequency.never.id
      t.integer :curation_on_my_watched_item, :default => NotificationFrequency.never.id
      t.integer :new_data_on_my_watched_item, :default => NotificationFrequency.never.id
      t.integer :changes_to_my_watched_collection, :default => NotificationFrequency.never.id
      t.integer :changes_to_my_watched_community, :default => NotificationFrequency.never.id
      t.integer :member_joined_my_watched_community, :default => NotificationFrequency.never.id
      t.integer :member_left_my_community, :default => NotificationFrequency.never.id
      t.integer :new_manager_in_my_community, :default => NotificationFrequency.never.id
      t.integer :i_am_being_watched, :default => NotificationFrequency.never.id
      t.datetime :last_notification_sent_at
      t.timestamps
    end

    add_column :users, :email_notifications, :boolean, :default => true

    User.all(:select => 'id').each do |user|
      Notification.create(:user_id => user.id)
    end

  end

  def self.down
    remove_column :users, :email_notifications
    drop_table :notifications
    drop_table :notification_frequencies
  end
end
