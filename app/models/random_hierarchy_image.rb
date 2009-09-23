#
# ... why is this a model / table?   Why isn't this just TaxonConcept.random?   ...Because the table itself is
# randomized to save time: we can grab 10 (or however many) taxa in a row and know that they are non-contiguous.
#
class RandomHierarchyImage < SpeciesSchemaModel
  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :hierarchy
  belongs_to :taxon_concept
  
  delegate :quick_scientific_name, :to => :taxon_concept
  delegate :quick_common_name, :to => :taxon_concept
  
  @@last_cleared = []
  @@count = []
  
  def self.random_set(limit = 10, hierarchy = nil)
    hierarchy ||= Hierarchy.default
    list = []
    RandomHierarchyImage.reset_count(hierarchy)
    starting_id = rand(@@count[hierarchy.id] - limit).floor
    starting_id = 0 if starting_id > (@@count[hierarchy.id] - limit) # This only applies when there are very few RandomTaxa.
    list = RandomHierarchyImage.find_by_sql(['SELECT rhi.* FROM random_hierarchy_images rhi WHERE rhi.hierarchy_id=? LIMIT ?, ?', hierarchy.id, starting_id, limit])
    list = self.random_set(limit, Hierarchy.default) if list.blank? && hierarchy.id != Hierarchy.default.id
    #raise "Found no Random Taxa in the database (#{starting_id}, #{limit})" if list.blank?
    return list
  end
  
  # The first one takes a little longer, since it needs to populate the class variables.  But after that, it's quite fast:
  def self.random(hierarchy = nil)
    return self.random_set(1, hierarchy)[0]
  end

  def self.reset_count(hierarchy)
    if @@last_cleared[hierarchy.id].blank? || @@last_cleared[hierarchy.id].advance(:hours=>1) < Time.now
      @@last_cleared[hierarchy.id] = Time.now()
      @@count[hierarchy.id] = SpeciesSchemaModel.connection.select_value("select count(*) count from random_hierarchy_images rhi WHERE rhi.hierarchy_id=#{hierarchy.id}").to_i
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
    return data_object.object_cache_url
  end
  
end
