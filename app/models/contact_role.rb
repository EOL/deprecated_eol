# We allow multiple "kinds" of ContentPartnerContact relationships.  Primary Contact is the only role that is used within the code: the
# rest are for the convenience of administrators.
class ContactRole < ActiveRecord::Base
  uses_translations
  has_many :content_partner_contacts
  
  def self.primary
    cached_find_translated(:label, 'Primary Contact', 'en')
  end
end
