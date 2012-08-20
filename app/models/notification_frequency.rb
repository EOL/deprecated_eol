class NotificationFrequency < ActiveRecord::Base

  attr_accessible :frequency

  def self.create_defaults
    NotificationFrequency.create(:frequency => 'never')
    NotificationFrequency.create(:frequency => 'newsfeed only')
    NotificationFrequency.create(:frequency => 'weekly')
    NotificationFrequency.create(:frequency => 'daily digest')
    NotificationFrequency.create(:frequency => 'send immediately')
  end

  def self.never
    cached_find(:frequency, 'never')
  end

  def self.daily
    cached_find(:frequency, 'daily digest')
  end

  def self.immediately
    cached_find(:frequency, 'send immediately')
  end

  def self.weekly
    cached_find(:frequency, 'weekly')
  end

  def self.newsfeed_only
    cached_find(:frequency, 'newsfeed only')
  end

  def translated_label
    I18n.t("notification_frequency_#{frequency.gsub(' ', '_').downcase}") # Using gsub just in case for future.
  end

end
