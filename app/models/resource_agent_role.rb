class ResourceAgentRole < SpeciesSchemaModel
  belongs_to :agent_resource

  def self.content_partner_upload_role
    @@content_partner_upload_role ||= ResourceAgentRole.find_by_label('Data Supplier')
  end

end

# == Schema Info
# Schema version: 20080922224121
#
# Table name: resource_agent_roles
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null

# == Schema Info
# Schema version: 20081020144900
#
# Table name: resource_agent_roles
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null

