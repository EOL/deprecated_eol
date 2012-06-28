#
# ... why is this a model / table?   Why isn't this just TaxonConcept.random?   ...Because the table itself is
# randomized to save time: we can grab 10 (or however many) taxa in a row and know that they are non-contiguous.
#
class RandomHierarchyImage < ActiveRecord::Base
  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :hierarchy
  belongs_to :taxon_concept

  delegate :quick_scientific_name, :to => :taxon_concept
  delegate :quick_common_name, :to => :taxon_concept

  def self.random_set_cached
    begin
      RandomHierarchyImage.random_set_precache_class_loads
      $CACHE.fetch('homepage/random_images', :expires_in => 30.minutes) do
        RandomHierarchyImage.random_set(12)
      end
    rescue TypeError => e
      # TODO - FIXME  ... This appears to have to do with $CACHE.fetch (obviously)... not sure why, though.
      RandomHierarchyImage.random_set(12)
    end
  end

  # Classes that MUST be loaded before attempting to cache random images.
  def self.random_set_precache_class_loads
    DataObject
    TaxonConcept
    TaxonConceptPreferredEntry
    Name
    TaxonConceptExemplarImage
    Hierarchy
  end

  def self.random_set(limit = 10, hierarchy = nil, options = {})
    hierarchy ||= Hierarchy.default
    options[:size] ||= '130_130'
    options[:language] ||= Language.english

    starting_id = rand(self.hierarchy_count(hierarchy) - limit).floor
    # This next line only applies when there are very few RandomTaxa.
    starting_id = 0 if starting_id > (self.hierarchy_count(hierarchy) - limit)
    starting_id = starting_id + self.min_id()

    # this query now grabs all the metadata we'll need including:
    # sci_name, common_name, taxon_concept_id, object_cache_url
    # it also looks for twice the limit as we still have some concepts with more than one preferred common name

    if $HOMEPAGE_MARCH_RICHNESS_THRESHOLD
      random_image_result = RandomHierarchyImage.find(:all,
        :conditions => "hierarchy_id=#{hierarchy.id} AND random_hierarchy_images.id>#{starting_id} AND tcm.richness_score>#{$HOMEPAGE_MARCH_RICHNESS_THRESHOLD.to_s} AND tc.published=1",
        :joins => "JOIN taxon_concept_metrics tcm USING (taxon_concept_id) JOIN taxon_concepts tc ON tc.id=random_hierarchy_images.taxon_concept_id",
        :limit => limit*2)
    else
      random_image_result = RandomHierarchyImage.find(:all,
        :conditions => "hierarchy_id=#{hierarchy.id} AND random_hierarchy_images.id>#{starting_id} AND tc.published=1",
        :joins => "JOIN taxon_concepts tc ON tc.id=random_hierarchy_images.taxon_concept_id",
        :limit => limit*2)
    end

    used_concepts = {}
    random_images = []
    random_image_result.each do |ri|
      next if !used_concepts[ri.taxon_concept_id].nil?
      random_images << ri
      used_concepts[ri.taxon_concept_id] = true
      break if random_images.length >= limit
    end

    RandomHierarchyImage.preload_associations(random_image_result,
      [ :data_object,
        { :taxon_concept => [
          { :preferred_entry => { :hierarchy_entry => [ :hierarchy, { :name => [ :canonical_form, :ranked_canonical_form ] } ] } },
          { :taxon_concept_exemplar_image => :data_object },
          { :preferred_common_names => :name } ] } ],
      :select => {
        :data_objects => [ :id, :object_cache_url, :data_type_id, :guid ],
        :names => [ :id, :italicized, :string, :canonical_form_id, :ranked_canonical_form_id ],
        :canonical_forms => [ :id, :string ],
        :taxon_concepts => [ :id ],
        :hierarchies => '*',
        :taxon_concept_names => '*' })

    random_images = self.random_set(limit, Hierarchy.default, :size => options[:size]) if random_images.blank? && hierarchy.id != Hierarchy.default.id
    #raise "Found no Random Taxa in the database (#{starting_id}, #{limit})" if random_images.blank?

    # by calling this here, the cached values will contain the pre-cached name. This saves a bunch of load time on the homepage
    random_images.each{ |r| r.taxon_concept.title_canonical }
    return random_images
  end

  # The first one takes a little longer, since it needs to populate the class variables.  But after that, it's quite fast:
  def self.random(hierarchy = nil, options = {})
    return self.random_set(1, hierarchy, options)[0]
  end

  def self.min_id()
    $CACHE.fetch('random_hierarchy_image/min_id', :expires_in => 60.minutes) do
      self.connection.select_value("select min(id) min from random_hierarchy_images").to_i
    end
  end

  def self.hierarchy_count(hierarchy)
    hierarchy ||= Hierarchy.default
    $CACHE.fetch("random_hierarchy_image/hierarchy_count_#{hierarchy.id}", :expires_in => 60.minutes) do
      self.connection.select_value("select count(*) count from random_hierarchy_images rhi WHERE rhi.hierarchy_id=#{hierarchy.id}").to_i
    end
  end

end
