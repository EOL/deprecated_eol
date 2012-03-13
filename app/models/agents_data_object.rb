# Joins an Agent to a DataObject via an AgentRole.
class AgentsDataObject < ActiveRecord::Base

  belongs_to :data_object
  belongs_to :agent
  belongs_to :agent_role
  set_primary_keys :data_object_id, :agent_id, :agent_role_id

  def self.sort_by_role_for_owner(users_data_objects)
    @@owner_roles_preferred_order ||= [ AgentRole.author, AgentRole.photographer, AgentRole.source,
                                        AgentRole.editor, AgentRole.contributor ]
    users_data_objects.sort_by do |udo|
      # 10 is some number higher than @@owner_roles_preferred_order.length, which we could use instead
      agent_role_weight = @@owner_roles_preferred_order.index(udo.agent_role) || 10
      if !udo.agent
        # some number higher than the above which will place UDO's with an agent missing for whatever
        # reason at the end of the list. Should be caught for later anyway
        agent_role_weight = 100
      end
      [ agent_role_weight, udo.view_order ]
    end
  end

end
