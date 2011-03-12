class TranslatedAgentStatus < SpeciesSchemaModel
  belongs_to :agent_status
  belongs_to :language
end
