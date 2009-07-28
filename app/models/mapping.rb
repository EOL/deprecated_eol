# TODO - ADD COMMENTS
class Mapping < SpeciesSchemaModel
  belongs_to :collection
  belongs_to :name

  delegate :ping_host?, :to => :collection

  def ping_host_url
    return collection.ping_host_url.gsub(/%ID%/, foreign_key)
  end
  
  def url
    return collection.uri.gsub(/FOREIGNKEY/, foreign_key)
  end

  def self.for_taxon_concept_id(tc_id)
    Mapping.find_by_sql(%Q{
      SELECT DISTINCT m.id, m.collection_id, m.name_id, m.foreign_key
        FROM taxon_concept_names tcn
          JOIN mappings m ON (tcn.name_id=m.name_id)
          JOIN collections c ON (m.collection_id=c.id)
          JOIN agents a ON (c.agent_id=a.id)
        WHERE tcn.taxon_concept_id = #{tc_id}
        GROUP BY c.id                        -- Mapping#for_taxon_concept_id
    })
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: mappings
#
#  id            :integer(4)      not null, primary key
#  collection_id :integer(3)      not null
#  name_id       :integer(4)      not null
#  foreign_key   :string(600)     not null

