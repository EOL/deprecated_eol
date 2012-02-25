class TranslatedAgentRole < ActiveRecord::Base
  belongs_to :agent_role
  belongs_to :language
end
