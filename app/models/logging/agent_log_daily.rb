class AgentLogDaily < LogDaily
  set_unique_data_column :integer, :agent_id

  def unique_data_to_s
    agent.full_name
  end
  
end
