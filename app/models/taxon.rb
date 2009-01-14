# In biological terms, a taxon is an organism (or group of organisms). The species Gadus morhua is a taxon, as
#  is the genus Gadus, as is the family Gadidae, as is the kingdom Animalia. All of those terms represent
#  taxa. So, it might be easiest to think of a taxon as a node in a taxonomic hierarchy. This is the general
#  biological definition, but our 'taxa' table is more specialized to deal with different interpretations of
#  taxa.

# A taxon in the context of the 'taxa' table is metadata about an organism (or group of organisms) that we
#  receive from our content partners. Our content partners prepare XML documents which contain taxon elements,
#  and these taxon elements have zero to many data objects associated with them. These two elements map to our
#  'taxa' and 'data_objects' tables respectively. In our 'taxa' table we store metadata about what our content
#  partners think the organism is - its name, what family its in, their local identifier for that taxon, etc.
#  They will also potentially include common names and references for their taxa.

# The basic theme here is that there is no standard definition of what a 'taxon' or species is. There are no
#  clear lines drawn between different species, so some content partner's interpretation of what a species is
#  will be different from another's. We therefore need to store all metadata that we get from content partners,
#  and the 'taxa' table is where we store it. We eventually try to reconcile these different interpretations
#  into a common understanding of the species, and these common understandings are what we are currently
#  calling taxon concepts.
class Taxon < SpeciesSchemaModel

  belongs_to :name

  has_and_belongs_to_many :resource
  has_and_belongs_to_many :refs
  has_and_belongs_to_many :common_names
  has_and_belongs_to_many :data_objects
  has_and_belongs_to_many :harvest_events
  
  has_many :data_objects_taxa
  has_many :resources_taxa

  has_many :taxon_concepts, :through => :names

  # This doesn't work:
  # has_and_belongs_to_many :taxon_concepts, :join_table => :taxon_concept_names, :foreign_key => :name_id, :association_foreign_key => :name_id, :uniq => true
  # So I'm doing this, instead.  It's another one of those composite primary key problems.
  def taxon_concepts
    TaxonConceptName.find_all_by_name_id(name_id).collect { |name| name.taxon_concept }
  end

  def title(expertise = :middle)
    return "" if scientific_name.nil? || common_name.nil? 
    case expertise
    when :expert
      self.scientific_name || ""
    else
      self.common_name || ""
    end
  end  
  
end
# == Schema Info
# Schema version: 20080923175821
#
# Table name: taxa
#
#  id                :integer(4)      not null, primary key
#  name_id           :integer(4)      not null
#  resource_id       :integer(4)      not null
#  guid              :string(20)      not null
#  identifier        :string(255)     not null
#  scientific_name   :string(255)     not null
#  source_url        :string(255)     not null
#  taxon_class       :string(255)     not null
#  taxon_family      :string(255)     not null
#  taxon_kingdom     :string(255)     not null
#  taxon_order       :string(255)     not null
#  taxon_phylum      :string(255)     not null
#  created_at        :timestamp       not null
#  taxon_created_at  :timestamp       not null
#  taxon_modified_at :timestamp       not null
#  updated_at        :timestamp       not null

# == Schema Info
# Schema version: 20081020144900
#
# Table name: taxa
#
#  id              :integer(4)      not null, primary key
#  name_id         :integer(4)      not null
#  guid            :string(32)      not null
#  scientific_name :string(255)     not null
#  taxon_class     :string(255)     not null
#  taxon_family    :string(255)     not null
#  taxon_kingdom   :string(255)     not null
#  taxon_order     :string(255)     not null
#  taxon_phylum    :string(255)     not null
#  created_at      :timestamp       not null
#  updated_at      :timestamp       not null

