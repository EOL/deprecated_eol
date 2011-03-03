class ResourceAgentRole < SpeciesSchemaModel
  belongs_to :agent_resource

  def self.content_partner_upload_role
    $LOCAL_CACHE.resource_agent_role_upload_role ||= cached('content_partner_upload', :serialize => true) do
      ResourceAgentRole.find_or_create_by_label('Data Supplier')
    end
  end
  
  class << self
    alias :data_supplier :content_partner_upload_role 
  end
  

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: resource_agent_roles
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null

