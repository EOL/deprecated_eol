# Joins an Agent to a DataObject via an AgentRole.
class AgentsDataObject < SpeciesSchemaModel

  belongs_to :data_object
  belongs_to :agent
  belongs_to :agent_role
  set_primary_keys :data_object_id, :agent_id, :agent_role_id

  # Allows us to create a "fake" entry (which never hits the database) for licenses... a way to add copyright
  # to attributions.
  def self.from_license license, rights_statement
    AgentsDataObject.new :agent => Agent.from_license(license, rights_statement),
                         :agent_role => AgentRole.new(:label => 'Copyright'), :view_order => 0
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: agents_data_objects
#
#  agent_id       :integer(4)      not null
#  agent_role_id  :integer(1)      not null
#  data_object_id :integer(4)      not null
#  view_order     :integer(1)      not null

