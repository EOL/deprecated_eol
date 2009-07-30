#
# ... why is this a model / table?   Why isn't this just TaxonConcept.random?   ...Because the table itself is
# randomized to save time: we can grab 10 (or however many) taxa in a row and know that they are non-contiguous.
#
class RandomTaxon < SpeciesSchemaModel
  belongs_to :language
  belongs_to :data_object
  belongs_to :taxon_concept
  
  delegate :quick_scientific_name, :to => :taxon_concept
  delegate :quick_common_name, :to => :taxon_concept
  delegate :scientific_name, :to => :taxon_concept
  delegate :common_name, :to => :taxon_concept
  
  @@min     = nil
  @@max     = nil
  @@cl4_min = nil
  @@cl4_max = nil
  @@last_cleared = nil
  @@count = []
  @@looping = false

  def self.random_set(limit = 10, hierarchy = nil)
    hierarchy ||= Hierarchy.default
    list = []
    RandomTaxon.reset_count(hierarchy)
    starting_id = rand(@@count[hierarchy.id] - limit).floor
    starting_id = 0 if starting_id > (@@count[hierarchy.id] - limit) # This only applies when there are very few RandomTaxa.
    list = RandomTaxon.find_by_sql(['SELECT rt.* FROM random_taxa rt JOIN hierarchy_entries he ON (rt.taxon_concept_id=he.taxon_concept_id) WHERE he.hierarchy_id=? LIMIT ?, ?', hierarchy.id, starting_id, limit])
    raise "Found no Random Taxa in the database (#{starting_id}, #{limit})" if list.blank?
    return list
  end
  
  # The first one takes a little longer, since it needs to populate the class variables.  But after that, it's quite fast:
  def self.random(hierarchy = nil)
    return self.random_set(1, hierarchy)[0]
  end

  def self.reset_count(hierarchy)
    if @@last_cleared.blank? || @@last_cleared.advance(:hours=>1) < Time.now
      @@last_cleared = Time.now()
      @@count[hierarchy.id] = SpeciesSchemaModel.connection.select_value("select count(*) count from random_taxa rt JOIN hierarchy_entries he ON (rt.taxon_concept_id=he.taxon_concept_id) WHERE he.hierarchy_id=#{hierarchy.id}").to_i
    end
  end

  # So, if we just called name(), return our cached version; otherwise, delegate to HE.
  def name(*args)
    args.empty? ? self[:name] : taxon_concept.name(args[0], args[1])
  end
  
  def smart_thumb
    self.data_object.smart_thumb
  end
  
  def smart_medium_thumb
    #return thumb_url.sub(/_small\.png/, '_medium.png')
    self.data_object.smart_medium_thumb
  end
  
  def smart_image
    return image_url
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: random_taxa
#
#  id               :integer(4)      not null, primary key
#  data_object_id   :integer(4)      not null
#  language_id      :integer(4)      not null
#  name_id          :integer(4)      not null
#  taxon_concept_id :integer(4)
#  common_name_en   :string(255)     not null
#  common_name_fr   :string(255)     not null
#  content_level    :integer(4)      not null
#  image_url        :string(255)     not null
#  name             :string(255)     not null
#  thumb_url        :string(255)     not null
#  created_at       :timestamp       not null

