class NotificationFrequency < ActiveRecord::Base

  attr_accessible :frequency

  include Enumerated
  enumerated :frequency, [
    'never',
    'newsfeed only',
    'weekly',
    {daily: 'daily digest'},
    {immediately: 'send immediately'}
  ]

  def self.create_defaults
    NotificationFrequency.create(:frequency => 'never') unless self.never
    NotificationFrequency.create(:frequency => 'newsfeed only') unless self.newsfeed_only
    NotificationFrequency.create(:frequency => 'weekly') unless self.weekly
    NotificationFrequency.create(:frequency => 'daily digest') unless self.daily
    NotificationFrequency.create(:frequency => 'send immediately') unless self.immediately
  end

  def translated_label
    I18n.t("notification_frequency_#{frequency.gsub(' ', '_').downcase}") # Using gsub just in case for future.
  end

end
