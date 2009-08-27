class UpdateAgentStatusForContentPartner < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    execute("UPDATE agents SET agent_status_id=#{AgentStatus.active.id} WHERE username<>'' AND (agent_status_id is null OR agent_status_id='')")
    AgentStatus.create(:label=>'Inactive')
    add_column :content_partners, :admin_notes, :text, :default=>''
  end

  def self.down
    remove_column :content_partners,:admin_notes
    item=AgentStatus.find_by_label('Inactive')
    item.destroy if item
  end

end
