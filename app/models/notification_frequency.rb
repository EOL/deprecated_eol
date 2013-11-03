class NotificationFrequency < ActiveRecord::Base

  attr_accessible :frequency

  include NamedDefaults

  set_defaults :frequency,
    [{frequency: 'never'},
     {frequency: 'newsfeed only'},
     {frequency: 'weekly'},
     {frequency: 'daily digest', method_name: :daily},
     {frequency: 'send immediately', method_name: :immediately}]

  # Note that we don't use the uses_translations thingie:
  def translated_label
    I18n.t("notification_frequency_#{frequency.gsub(' ', '_').downcase}") # Using gsub just in case for future.
  end

end
