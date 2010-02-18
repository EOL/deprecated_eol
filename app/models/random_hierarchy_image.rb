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
  @@last_min_count = nil
  @@min_id = 0
  
  def self.random_set(limit = 10, hierarchy = nil, options = {})
    hierarchy ||= Hierarchy.default
    options[:size] ||= :medium
    options[:language] ||= Language.english
    
    RandomHierarchyImage.reset_min_id
    RandomHierarchyImage.reset_count(hierarchy)
    starting_id = rand(@@count[hierarchy.id] - limit).floor
    starting_id = 0 if starting_id > (@@count[hierarchy.id] - limit) # This only applies when there are very few RandomTaxa.
    starting_id = starting_id + @@min_id
    
    # this query now grabs all the metadata we'll need including:
    # sci_name, common_name, taxon_concept_id, object_cache_url
    # it also looks for twice the limit as we still have some concepts with more than one preferred common name
    random_image_result = SpeciesSchemaModel.connection.select_all("
      SELECT rhi.taxon_concept_id, rhi.name scientific_name, n.string common_name, do.object_cache_url
      FROM random_hierarchy_images rhi
      JOIN data_objects do ON (rhi.data_object_id=do.id)
      LEFT JOIN (
        taxon_concept_names tcn
        JOIN names n ON (tcn.name_id=n.id AND tcn.language_id=#{options[:language].id} AND tcn.preferred=1)
      ) ON (rhi.taxon_concept_id=tcn.taxon_concept_id)
      WHERE rhi.hierarchy_id=#{hierarchy.id}
      AND rhi.id>#{starting_id} LIMIT #{limit*2}")
    
    used_concepts = {}
    random_images = []
    random_image_result.each do |ri|
      next if !used_concepts[ri['taxon_concept_id']].nil?
      ri['image_cache_path'] = DataObject.image_cache_path(ri['object_cache_url'], options[:size])
      random_images << ri
      used_concepts[ri['taxon_concept_id']] = true
      break if random_images.length >= limit
    end
    
    random_images = self.random_set(limit, Hierarchy.default, :size => options[:size]) if random_images.blank? && hierarchy.id != Hierarchy.default.id
    #raise "Found no Random Taxa in the database (#{starting_id}, #{limit})" if random_images.blank?
    return random_images
  end
  
  # The first one takes a little longer, since it needs to populate the class variables.  But after that, it's quite fast:
  def self.random(hierarchy = nil, options = {})
    return self.random_set(1, hierarchy, options)[0]
  end
  
  def self.reset_min_id()
    if @@last_min_count.nil? || @@last_min_count.advance(:hours=>1) < Time.now
      @@last_min_count = Time.now()
      @@min_id = SpeciesSchemaModel.connection.select_value("select min(id) min from random_hierarchy_images").to_i
    end
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
