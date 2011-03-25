class TranslatedAgentDataType < SpeciesSchemaModel
  belongs_to :agent_data_type
  belongs_to :language
end
