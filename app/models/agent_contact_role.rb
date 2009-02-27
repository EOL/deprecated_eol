# We allow multiple "kinds" of AgentContact relationships.  Primary Contact is the only role that is used within the code: the
# rest are for the convenience of users.
class AgentContactRole < SpeciesSchemaModel
  has_many :agent_contacts
  
  def self.primary
    return @@primary ||= self.find_by_label('Primary Contact')
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: agent_contact_roles
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null

