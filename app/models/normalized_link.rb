# TODO - ADD COMMENTS
class NormalizedLink < SpeciesSchemaModel
  belongs_to :normalized_name
  belongs_to :name
  set_primary_keys [:normalized_name_id, :name_id]
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: normalized_links
#
#  name_id                 :integer(4)      not null
#  normalized_name_id      :integer(4)      not null
#  normalized_qualifier_id :integer(1)      not null
#  seq                     :integer(1)      not null

