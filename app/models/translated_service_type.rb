class TranslatedServiceType < ActiveRecord::Base
  belongs_to :service_type
  belongs_to :language
end
