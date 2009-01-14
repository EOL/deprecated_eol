class ResourcesTaxon < SpeciesSchemaModel

  # JRice removed this in an attempt to get things to work.  I know, I know: it's not right.  Rails is NOT built for composite
  # primary keys, *even* with the plugin.  It incorrectly assumes ALL referenes to this table will contain BOTH keys.
  # ...As long as we are not writing to the table, we should be okay without it:
  # set_primary_keys :data_object_id, :taxon_id

  belongs_to :resource
  belongs_to :taxon

  #has_many :taxa

end# == Schema Info
# Schema version: 20081002192244
#
# Table name: resources_taxa
#
#  resource_id       :integer(4)      not null
#  taxon_id          :integer(4)      not null
#  identifier        :string(255)     not null
#  source_url        :string(255)     not null
#  taxon_created_at  :timestamp       not null
#  taxon_modified_at :timestamp       not null

# == Schema Info
# Schema version: 20081020144900
#
# Table name: resources_taxa
#
#  resource_id       :integer(4)      not null
#  taxon_id          :integer(4)      not null
#  identifier        :string(255)     not null
#  source_url        :string(255)     not null
#  taxon_created_at  :timestamp       not null
#  taxon_modified_at :timestamp       not null

