class ResourceAgentRole < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  belongs_to :agent_resource

  def self.content_partner_upload_role
    cached_find(:label, 'Data Supplier')
  end
  
  class << self
    alias :data_supplier :content_partner_upload_role 
  end
  

end
