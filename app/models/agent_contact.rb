# These individuals are associated with the roles such as "administrative contact" or "technical contact"
# are not used for attribution or logging in - they are simply used for administrative purposes when
# contacting the project. 
class AgentContact < SpeciesSchemaModel
  belongs_to :agent  
  belongs_to :agent_contact_role

  validates_presence_of :given_name, :family_name
  #, :homepage, :telephone, :address, :agent_contact_role_id
  validates_format_of :email,
     :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => 'is not a valid e-mail address'
  before_save :blank_not_null_fields  
  before_save :save_full_name

  protected

    def save_full_name
      self.full_name = "#{self.given_name} #{self.family_name}".strip
    end
  
    def blank_not_null_fields
      self.title ||= ""
      self.full_name ||= ""
      self.address ||= ""
    end    
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: agent_contacts
#
#  id                    :integer(4)      not null, primary key
#  agent_contact_role_id :integer(1)      not null
#  agent_id              :integer(4)      not null
#  address               :text            not null
#  email                 :string(75)      not null
#  family_name           :string(255)     not null
#  full_name             :string(255)     not null
#  given_name            :string(255)     not null
#  homepage              :string(255)     not null
#  telephone             :string(30)      not null
#  title                 :string(20)      not null

