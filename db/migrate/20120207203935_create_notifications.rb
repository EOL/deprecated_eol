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
      t.boolean :eol_newsletter, :default => true
      t.datetime :last_notification_sent_at
      t.timestamps
    end

    add_column :users, :disable_email_notifications, :boolean, :default => false

    User.all(:select => 'id, mailing_list').each do |user|
      Notification.create(:user_id => user.id, :eol_newsletter => user.mailing_list)
    end

    remove_column :users, :mailing_list
    # TODO - Figure out how not to use it for content partners and remove it from users table. 
    # Do the same for last_report_email
    # remove_column :users, :email_reports_frequency_hours

  end

  def self.down
    add_column :users, :mailing_list, :boolean, :default => true
    execute "UPDATE users, notifications SET users.mailing_list = notifications.eol_newsletter WHERE users.id = notifications.user_id"
    remove_column :users, :disable_email_notifications
    drop_table :notifications
    drop_table :notification_frequencies
  end
end
