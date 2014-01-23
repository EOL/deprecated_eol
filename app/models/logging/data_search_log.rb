# This class is used to log data searches of TraitBank
class DataSearchLog < LazyLoggingModel
  establish_connection("#{Rails.env}_logging")

  belongs_to :user
  belongs_to :taxon_concept
  belongs_to :known_uri
  belongs_to :language

end
