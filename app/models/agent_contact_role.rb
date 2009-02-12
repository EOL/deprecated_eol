# See notes in "Agent" model.
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

