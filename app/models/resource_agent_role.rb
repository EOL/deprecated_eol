class ResourceAgentRole < SpeciesSchemaModel
  belongs_to :agent_resource

  def self.content_partner_upload_role
    YAML.load(Rails.cache.fetch('resource_agent_roles/content_partner_upload') do
      ResourceAgentRole.find_by_label('Data Supplier').to_yaml
    end)
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: resource_agent_roles
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null

