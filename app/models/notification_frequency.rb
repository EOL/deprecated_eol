class NotificationFrequency < ActiveRecord::Base

  def self.create_defaults
    NotificationFrequency.create(:frequency => 'never')
    NotificationFrequency.create(:frequency => 'daily')
    NotificationFrequency.create(:frequency => 'immediately')
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

end
