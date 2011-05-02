class UpdateAgentStatusForContentPartner < EOL::DataMigration

  def self.up
    EOL::DB::toggle_eol_data_connections(:eol_data)
    active_id = AgentStatus.find_by_label('active') ? AgentStatus.find_by_label('active') : '1' # ok, maybe the active state isn't in the database yet, so let's assume it will be 1
    execute("UPDATE agents SET agent_status_id=#{active_id} WHERE username!='' AND (agent_status_id is null OR agent_status_id='')")
    AgentStatus.create(:label=>'Inactive')
    add_column :content_partners, :admin_notes, :text, :default=>'' rescue nil
    EOL::DB::toggle_eol_data_connections(:eol)
  end

  def self.down
    EOL::DB::toggle_eol_data_connections(:eol_data)
    remove_column :content_partners,:admin_notes
    item=AgentStatus.find_by_label('Inactive')
    item.destroy if item
    EOL::DB::toggle_eol_data_connections(:eol)
  end

end
