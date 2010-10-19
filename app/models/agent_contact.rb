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
  
  def full_name
    self.save_full_name
  end
  
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
