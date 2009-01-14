class NormalizedName < SpeciesSchemaModel
  has_many :normalized_links
  # Nothing to do, here.  We just needed to point specs in the right direciton.
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: normalized_names
#
#  id        :integer(4)      not null, primary key
#  name_part :string(100)     not null

