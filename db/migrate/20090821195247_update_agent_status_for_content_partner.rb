class UpdateAgentStatusForContentPartner < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    active_id=(AgentStatus.active.blank? ? '1' : AgentStatus.active.id) # ok, maybe the active state isn't in the database yet, so let's assume it will be 1
    execute("UPDATE agents SET agent_status_id=#{active_id} WHERE username<>'' AND (agent_status_id is null OR agent_status_id='')")
    AgentStatus.create(:label=>'Inactive')
    add_column :content_partners, :admin_notes, :text, :default=>''
  end

  def self.down
    remove_column :content_partners,:admin_notes
    item=AgentStatus.find_by_label('Inactive')
    item.destroy if item
  end

end
