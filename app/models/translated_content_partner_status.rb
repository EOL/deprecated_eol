class TranslatedContentPartnerStatus < ActiveRecord::Base
  belongs_to :content_partner_status
  belongs_to :language
end
