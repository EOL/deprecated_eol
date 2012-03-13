class CreateNotificationEmailerSettings < ActiveRecord::Migration
  def self.up
    create_table :notification_emailer_settings do |t|
      t.datetime :last_daily_emails_sent
      t.datetime :last_weekly_emails_sent
      t.timestamps
    end
    NotificationEmailerSettings.create(:last_daily_emails_sent => Time.now(), :last_weekly_emails_sent => Time.now())
  end

  def self.down
    drop_table :notification_emailer_settings
  end
end
