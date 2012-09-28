#
# ... why is this a model / table?   Why isn't this just TaxonConcept.random?   ...Because the table itself is
# randomized to save time: we can grab 10 (or however many) taxa in a row and know that they are non-contiguous.
#
class RandomHierarchyImage < ActiveRecord::Base

  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :hierarchy
  belongs_to :taxon_concept

  has_many :taxon_concept_metrics, :primary_key => 'taxon_concept_id', :foreign_key => 'taxon_concept_id'

  def self.random_set_cached
    begin
      RandomHierarchyImage.random_set_precache_class_loads
      Rails.cache.fetch('homepage/random_images', :expires_in => 30.minutes) do
        RandomHierarchyImage.random_set(12)
      end
    rescue TypeError => e
      # TODO - FIXME  ... This appears to have to do with Rails.cache.fetch (obviously)... not sure why, though.
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
    Vetted
  end

  def self.random_set(limit = 10, hierarchy = nil, options = {})
    options[:size] ||= '130_130'
    options[:language] ||= Language.english
    
    if hierarchy
      starting_id = rand(self.hierarchy_count(hierarchy) - limit).floor
      # This next line only applies when there are very few RandomTaxa.
      starting_id = 0 if starting_id > (self.hierarchy_count(hierarchy) - limit)
      starting_id = starting_id + self.min_id()
    else
      starting_id = rand(self.max_id() - limit).floor
      # This next line only applies when there are very few RandomTaxa.
      starting_id = 0 if starting_id > (self.max_id() - limit)
    end

    # this query now grabs all the metadata we'll need including:
    # sci_name, common_name, taxon_concept_id, object_cache_url
    # it also looks for twice the limit as we still have some concepts with more than one preferred common name

    hierarchy_condition = hierarchy ? "AND hierarchy_id=#{hierarchy.id}" : ""
    random_image_result = if $HOMEPAGE_MARCH_RICHNESS_THRESHOLD
      RandomHierarchyImage.joins(:taxon_concept_metrics, :taxon_concept).
        where(["random_hierarchy_images.id > ? AND richness_score > ? AND published = 1 #{hierarchy_condition}",
              starting_id, $HOMEPAGE_MARCH_RICHNESS_THRESHOLD]).limit(limit * 2)
                          else
      RandomHierarchyImage.joins(:taxon_concept).
        where(["random_hierarchy_images.id > ? AND published=1 #{hierarchy_condition}", starting_id]).limit(limit * 2)
                          end

    used_concepts = {}
    random_images = []
    random_image_result.each do |ri|
      next if !used_concepts[ri.taxon_concept_id].nil?
      random_images << ri
      used_concepts[ri.taxon_concept_id] = true
      break if random_images.length >= limit
    end

    RandomHierarchyImage.preload_associations(random_images,
      [ { :taxon_concept => [
          { :preferred_entry => { :hierarchy_entry => [ :hierarchy, { :name => [ :canonical_form, :ranked_canonical_form ] } ] } },
          { :taxon_concept_exemplar_image => :data_object },
          { :preferred_common_names => :name } ] } ])

    random_images = self.random_set(limit, nil, :size => options[:size]) if random_images.blank? && hierarchy
    Rails.logger.warn "Found no Random Taxa in the database (#{starting_id}, #{limit})" if random_images.blank?

    # by calling this here, the cached values will contain the pre-cached name. This saves a bunch of load time on the homepage
    # random_images.each{ |r| r.taxon_concept.title_canonical }
    return random_images
  end

  def self.min_id()
    Rails.cache.fetch('random_hierarchy_image/min_id', :expires_in => 60.minutes) do
      self.connection.select_value("select min(id) min from random_hierarchy_images").to_i
    end
  end
  
  def self.max_id()
    Rails.cache.fetch('random_hierarchy_image/max_id', :expires_in => 60.minutes) do
      self.connection.select_value("select max(id) min from random_hierarchy_images").to_i
    end
  end
  

  def self.hierarchy_count(hierarchy)
    hierarchy ||= Hierarchy.default
    Rails.cache.fetch("random_hierarchy_image/hierarchy_count_#{hierarchy.id}", :expires_in => 60.minutes) do
      self.connection.select_value("select count(*) count from random_hierarchy_images rhi WHERE rhi.hierarchy_id=#{hierarchy.id}").to_i
    end
  end

end
