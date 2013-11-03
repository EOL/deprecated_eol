# We allow multiple "kinds" of ContentPartnerContact relationships.  Primary Contact is the only role that is used within the code: the
# rest are for the convenience of administrators.
class ContactRole < ActiveRecord::Base

  uses_translations

  has_many :content_partner_contacts
  
  include NamedDefaults
  set_defaults :label, [
    {method_name: :primary, label: 'Primary Contact'},
    {method_name: :administrative, label: 'Administrative Contact'},
    {method_name: :technical, label: 'Technical Contact'}
  ]

end
