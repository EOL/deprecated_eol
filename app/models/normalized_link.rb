#
# NormalizedLink joins NormalizedNames (unique name_parts) with 
# Names (which have many NormalizedNames thru NormalizedLinks)
#
# See Name and NormalizedName
#
class NormalizedLink < SpeciesSchemaModel

  belongs_to :normalized_name
  belongs_to :name

  set_primary_keys [:normalized_name_id, :name_id]

  # Parse a Name into NormalizedNames and link 
  # those back to the name via NormalizedLinks
  #
  # ==== Parameters
  # name<Name>::
  #   The Name that we'll parse into NormalizedNames, linked via NormalizedLinks
  #
  # ==== Returns
  # Array(NormalizedLink)::
  #   NormalizedLinks that connect the given Name to NormalizedNames
  #
  def self.parse! name
    normalized_names = NormalizedName.parse! name
    normalized_names.each_with_index do |normalized_name, index|
      name.normalized_links.create :normalized_name => normalized_name, :seq => index, 
                                   :normalized_qualifier_id => 1 # this one isn't used currently, but must == 1
    end
    name.normalized_links
  end

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

