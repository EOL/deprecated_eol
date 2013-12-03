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

  def translated_label
    I18n.t("notification_frequency_#{frequency.gsub(' ', '_').downcase}") # Using gsub just in case for future.
  end

end
