class AgentStatus < SpeciesSchemaModel
  
  has_many :content_partners
    
  def self.active
    @@active ||= AgentStatus.find_by_label('Active') 
  end 
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: agent_statuses
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null

