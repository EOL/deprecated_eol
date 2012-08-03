class NotificationEmailerSettings < ActiveRecord::Base
  self.table_name = 'notification_emailer_settings'
  
  def self.last_daily_emails_sent
    settings.last_daily_emails_sent
  end
  def self.last_daily_emails_sent=(new_time)
    settings.last_daily_emails_sent = new_time
    settings.save
  end
  
  def self.last_weekly_emails_sent
    settings.last_weekly_emails_sent
  end
  def self.last_weekly_emails_sent=(new_time)
    settings.last_weekly_emails_sent = new_time
    settings.save
  end
  
private
  def self.settings
    @@only_record ||= NotificationEmailerSettings.first
    if !@@only_record
      @@only_record = NotificationEmailerSettings.create(:last_daily_emails_sent => Time.now(), :last_weekly_emails_sent => Time.now())
    end
    @@only_record
  end
end
