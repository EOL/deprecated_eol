# ... why is this a model / table?   Why isn't this just TaxonConcept.random?
# ...Because the table itself is randomized to save time: we can grab 10 (or
# however many) taxa in a row and know that they are non-contiguous.
#
class RandomHierarchyImage < ActiveRecord::Base

  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :hierarchy
  belongs_to :taxon_concept

  has_many :taxon_concept_metrics, primary_key: 'taxon_concept_id', foreign_key: 'taxon_concept_id'

  class << self
    def random_set_cached
      RandomHierarchyImage.random_set_precache_class_loads
      Rails.cache.fetch('homepage/random_images', expires_in: 30.minutes) do
        RandomHierarchyImage.random_set(12)
      end
    rescue TypeError => e
      # TODO - FIXME  ... This appears to have to do with Rails.cache.fetch (obviously)... not sure why, though.
      RandomHierarchyImage.random_set(12)
    end

    # Classes that MUST be loaded before attempting to cache random images.
    def random_set_precache_class_loads
      DataObject
      TaxonConcept
      TaxonConceptPreferredEntry
      Name
      TaxonConceptExemplarImage
      Hierarchy
      Vetted
    end

    # TODO - rewrite this, it's WAY too complex. Most of these features are unused
    # and unnecessary. Also, it should just keep looking for random images until
    # it finds enough... not relying on the "limit * 3" thing to get more than it
    # needs. Of course, that algorithm will need to watch for endless loops.
    def random_set(limit = 10, hierarchy = nil, options = {})
      options[:size] ||= '130_130'
      options[:language] ||= Language.english

      if hierarchy
        starting_id = rand(hierarchy_count(hierarchy) - limit).floor
        # This next line only applies when there are very few RandomTaxa.
        starting_id = 0 if starting_id > (hierarchy_count(hierarchy) - limit)
        starting_id = starting_id + min_id()
      else
        starting_id = rand(max_id() - limit).floor
        # This next line only applies when there are very few RandomTaxa.
        starting_id = 0 if starting_id > (max_id() - limit)
      end

      # this query now grabs all the metadata we'll need including:
      # sci_name, common_name, taxon_concept_id, object_cache_url
      # it also looks for twice the limit as we still have some concepts with more than one preferred common name

      hierarchy_condition = hierarchy ? "AND hierarchy_id=#{hierarchy.id}" : ""
      random_image_result = if $HOMEPAGE_MARCH_RICHNESS_THRESHOLD
        RandomHierarchyImage.joins(:taxon_concept_metrics, :taxon_concept).
          where(["random_hierarchy_images.id > ? AND richness_score > ? AND published = 1 #{hierarchy_condition} AND supercedure_id = 0",
                starting_id, $HOMEPAGE_MARCH_RICHNESS_THRESHOLD]).limit(limit * 3)
                            else
        RandomHierarchyImage.joins(:taxon_concept).
          where(["random_hierarchy_images.id > ? AND published=1 #{hierarchy_condition} AND supercedure_id = 0", starting_id]).limit(limit * 3)
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
        [ { taxon_concept: [
            { preferred_entry: { hierarchy_entry: [ :hierarchy, { name: [ :canonical_form, :ranked_canonical_form ] } ] } },
            { taxon_concept_exemplar_image: :data_object },
            { preferred_common_names: :name } ] } ])

      random_images = random_set(limit, nil, size: options[:size]) if random_images.blank? && hierarchy
      Rails.logger.warn "Found no Random Taxa in the database (#{starting_id}, #{limit})" if random_images.blank?
      return random_images
    end

    def min_id()
      Rails.cache.fetch('random_hierarchy_image/min_id', expires_in: 60.minutes) do
        minimum(:id)
      end
    end

    def max_id()
      Rails.cache.fetch('random_hierarchy_image/max_id', expires_in: 60.minutes) do
        maximum(:id)
      end
    end


    def hierarchy_count(hierarchy)
      hierarchy ||= Hierarchy.default
      Rails.cache.fetch("random_hierarchy_image/hierarchy_count_#{hierarchy.id}", expires_in: 60.minutes) do
        connection.select_value("select count(*) count from random_hierarchy_images rhi WHERE rhi.hierarchy_id=#{hierarchy.id}").to_i
      end
    end

    def create_random_images_from_rich_taxa
      EOL.log_call
      tc_ids = TaxonConceptMetric.
        where(["richness_score > ?", $HOMEPAGE_MARCH_RICHNESS_THRESHOLD]).
        pluck(:taxon_concept_id)
      EOL.log("Found #{tc_ids} rich taxa", prefix: '.')
      # Not doing this with a big join right now because the top_concept_images
      # table was out of date at the time of writing. TODO - move the trusted
      # check; that should be done when called, not here!
      set = Set.new
      TaxonConcept.includes(hierarchy_entries: [ :name ]).
        where(id: tc_ids, vetted_id: Vetted.trusted.id).
        where(["hierarchy_entries.lft = hierarchy_entries.rgt - 1 OR "\
          "hierarchy_entries.rank_id IN (?)", Rank.species_rank_ids]).
        find_each do |taxon|
        img = taxon.exemplar_or_best_image_from_solr
        next unless img
        set << {
          data_object_id: img.id,
          hierarchy_entry_id: taxon.entry.id,
          hierarchy_id: taxon.entry.hierarchy_id,
          taxon_concept_id:taxon.id,
          name: taxon.entry.name.italicized
        }
      end
      EOL.log("Found #{set.count} of species with images", prefix: '.')
      RandomHierarchyImage.connection.transaction do
        RandomHierarchyImage.delete_all
        # TODO - this could be much faster with a bulk insert
        set.to_a.shuffle.each do |values|
          RandomHierarchyImage.create(values)
        end
      end
    end

  end

end
