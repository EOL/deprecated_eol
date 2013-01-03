class TranslatedActivity < LoggingModel
  establish_connection("#{Rails.env}_logging")
  belongs_to :activity
  belongs_to :language
end
