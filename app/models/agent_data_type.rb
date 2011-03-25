# This is not a class used in the code.  However, the data represents what content partners will be providing, which helps us
# prioritize harvests (for example, when we feel we need videos, we can find content partners promising video data).
class AgentDataType < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :agent_provided_data_types
end
