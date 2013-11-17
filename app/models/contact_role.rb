# We allow multiple "kinds" of ContentPartnerContact relationships.  Primary Contact is the only role that is used within the
# code: the rest are for the convenience of administrators.
class ContactRole < ActiveRecord::Base

  uses_translations
  has_many :content_partner_contacts

  include Enumerated
  enumerated :label, ['Primary Contact']
  
end
