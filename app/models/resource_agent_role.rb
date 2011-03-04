class ResourceAgentRole < SpeciesSchemaModel
  belongs_to :agent_resource

  def self.content_partner_upload_role
    cached('content_partner_upload') do
      ResourceAgentRole.find_or_create_by_label('Data Supplier')
    end
  end
  
  class << self
    alias :data_supplier :content_partner_upload_role 
  end
  

end
