class NotificationFrequency < ActiveRecord::Base

  def self.create_defaults
    NotificationFrequency.create(:frequency => 'never')
    NotificationFrequency.create(:frequency => 'weekly')
    NotificationFrequency.create(:frequency => 'daily digest')
    NotificationFrequency.create(:frequency => 'send immediately')
  end

  def self.never
    cached_find(:frequency, 'never')
  end

  def self.daily
    cached_find(:frequency, 'daily')
  end

  def self.immediately
    cached_find(:frequency, 'immediately')
  end

  def translated_label
    I18n.t("notification_frequency_#{frequency.gsub(' ', '_').downcase}") # Using gsub just in case for future.
  end

end
