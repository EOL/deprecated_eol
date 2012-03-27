# Represents a group of HierearchyEntry instances that we consider "the same".  This amounts to a vague idea
# of a taxon, which we serve as a single page.
#
# We get different interpretations of taxa from our partners (ContentPartner), often differing slightly
# and referring to basically the same thing, so TaxonConcept was created as a means to reconcile the
# variant definitions of what are essentially the same Taxon. We currently store basic Taxon we receive
# from data imports in the +hierarchy_entries+ table and we also store taxonomic hierarchies (HierarchyEntry) in the
# +hierarchy_entries+ table. Currently TaxonConcept are groups of one or many HierarchyEntry. We will
# eventually create hierarchy_entries for each entry in the taxa table (Taxon).
#
# It is worth mentioning that the "eol.org/pages/nnnn" route is a misnomer.  Those IDs are, for the
# time-being, pointing to TaxonConcept, not pages.
#
# See the comments at the top of the Taxon for more information on this.
# I include there a basic biological definition of what a Taxon is.
class TaxonConcept < ActiveRecord::Base
  include ModelQueryHelper
  include EOL::ActivityLoggable

  belongs_to :vetted

  has_many :feed_data_objects
  has_many :hierarchy_entries
  has_many :published_hierarchy_entries, :class_name => HierarchyEntry.to_s,
    :conditions => 'hierarchy_entries.published=1 AND hierarchy_entries.visibility_id=#{Visibility.visible.id}'

  has_many :published_browsable_hierarchy_entries, :class_name => HierarchyEntry.to_s, :foreign_key => 'id',
    :finder_sql => 'SELECT he.id, he.rank_id, h.id hierarchy_id, h.label hierarchy_label
    FROM hierarchies h
    JOIN hierarchy_entries he ON h.id = he.hierarchy_id
    WHERE he.taxon_concept_id = \'#{id}\' AND he.published = 1 and h.browsable = 1
    ORDER BY h.label'

  has_many :top_concept_images
  has_many :top_unpublished_concept_images
  has_many :curator_activity_logs
  has_many :taxon_concept_names
  has_many :comments, :as => :parent
  has_many :names, :through => :taxon_concept_names
  has_many :ranks, :through => :hierarchy_entries
  has_many :google_analytics_partner_taxa
  has_many :collection_items, :as => :object
  has_many :collections, :through => :collection_items
  # TODO: this is just an alias of the above so all collectable entities have this association
  has_many :containing_collections, :through => :collection_items, :source => :collection
  has_many :preferred_names, :class_name => TaxonConceptName.to_s, :conditions => 'taxon_concept_names.vern=0 AND taxon_concept_names.preferred=1'
  has_many :preferred_common_names, :class_name => TaxonConceptName.to_s, :conditions => 'taxon_concept_names.vern=1 AND taxon_concept_names.preferred=1'
  has_many :denormalized_common_names, :class_name => TaxonConceptName.to_s, :conditions => 'taxon_concept_names.vern=1'
  has_many :synonyms, :class_name => Synonym.to_s, :foreign_key => 'hierarchy_entry_id',
    :finder_sql => 'SELECT s.* FROM #{Synonym.full_table_name} s JOIN #{HierarchyEntry.full_table_name} he ON (he.id = s.hierarchy_entry_id) WHERE he.taxon_concept_id=\'#{id}\' AND s.synonym_relation_id NOT IN (#{SynonymRelation.common_name_ids.join(",")})'
  has_many :viewable_synonyms, :class_name => Synonym.to_s, :foreign_key => 'hierarchy_entry_id',
    :finder_sql => 'SELECT s.* FROM #{Synonym.full_table_name} s JOIN #{HierarchyEntry.full_table_name} he ON (he.id = s.hierarchy_entry_id) JOIN #{Hierarchy.full_table_name} h ON (he.hierarchy_id=h.id) WHERE he.taxon_concept_id=\'#{id}\' AND he.published=1 AND he.visibility_id=#{Visibility.visible.id} AND h.browsable=1 AND s.synonym_relation_id NOT IN (#{SynonymRelation.common_name_ids.join(",")})'
  has_many :users_data_objects
  has_many :flattened_ancestors, :class_name => TaxonConceptsFlattened.to_s
  has_many :all_data_objects, :class_name => DataObject.to_s, :finder_sql => '
      (SELECT do.id, do.data_type_id, do.published, do.guid, do.data_rating, do.language_id
        FROM data_objects_taxon_concepts dotc
        JOIN data_objects do ON (dotc.data_object_id=do.id)
          WHERE dotc.taxon_concept_id=#{id}
          AND do.data_type_id=#{DataType.image.id})
      UNION
      (SELECT do.id, do.data_type_id, do.published, do.guid, do.data_rating, do.language_id
        FROM top_concept_images tci
        JOIN data_objects do ON (tci.data_object_id=do.id)
          WHERE tci.taxon_concept_id=#{id})
      UNION
      (SELECT do.id, do.data_type_id, do.published, do.guid, do.data_rating, do.language_id
        FROM #{UsersDataObject.full_table_name} udo
        JOIN data_objects do ON (udo.data_object_id=do.id)
          WHERE udo.taxon_concept_id=#{id})'

  has_many :superceded_taxon_concepts, :class_name => TaxonConcept.to_s, :foreign_key => "supercedure_id"

  has_one :taxon_concept_metric
  has_one :taxon_concept_exemplar_image
  has_one :taxon_concept_preferred_entry

  has_and_belongs_to_many :data_objects

  attr_accessor :includes_unvetted # true or false indicating if this taxon concept has any unvetted/unknown data objects

  attr_reader :has_media, :length_of_images, :length_of_videos, :length_of_sounds

  index_with_solr :keywords => [ :scientific_names_for_solr, :common_names_for_solr ]

  define_core_relationships :select => {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :names => :string,
      :vetted => :view_order,
      :canonical_forms => :string,
      :data_objects => [ :id, :data_type_id, :published, :guid, :data_rating, :language_id, :object_cache_url ],
      :licenses => :title,
      :table_of_contents => '*' },
    :include => [{ :published_hierarchy_entries => [ :name , :hierarchy, :vetted ] }, { :data_objects => [ { :toc_items => :info_items }, :license] },
      { :users_data_objects => { :data_object => :toc_items } }]

  def all_superceded_taxon_concept_ids
    # arbitrarily 
    superceded_taxon_concept_ids = []
    TaxonConcept.preload_associations(self, { :superceded_taxon_concepts => { :superceded_taxon_concepts => { :superceded_taxon_concepts => :superceded_taxon_concepts } } }, :select => { :taxon_concepts => [ :id, :supercedure_id ] } )
    superceded_taxon_concepts.each do |superceded_concept|
      superceded_taxon_concept_ids << superceded_concept.id
      superceded_taxon_concept_ids += superceded_concept.all_superceded_taxon_concept_ids
    end
    superceded_taxon_concept_ids.uniq
  end

  # The common name will defaut to the current user's language.
  def common_name(hierarchy = nil)
    quick_common_name(hierarchy)
  end

  def preferred_common_name_in_language(language)
    best_name_in_language = preferred_common_names.detect do |preferred_common_name|
      preferred_common_name.language_id == language.id
    end
    best_name_in_language.name.string if best_name_in_language
  end

  # TODO - this will now be called on ALL taxon pages.  Eep!  Make this more efficient:
  def common_names(options = {})
    if options[:hierarchy_entry_id]
      tcn = TaxonConceptName.find_all_by_source_hierarchy_entry_id_and_vern(options[:hierarchy_entry_id], 1, :include => [ :name, :language ],
        :select => {:taxon_concept_names => [ :preferred, :vetted_id ], :names => :string, :languages => '*'})
    else
      tcn = TaxonConceptName.find_all_by_taxon_concept_id_and_vern(self.id, 1, :include => [ :name, :language ],
        :select => {:taxon_concept_names => [ :preferred, :vetted_id ], :names => :string, :languages => '*'})
    end

    sorted_names = TaxonConceptName.sort_by_language_and_name(tcn)
    duplicate_check = {}
    name_languages = {}
    # remove duplicate names in the same language
    sorted_names.each_with_index do |tcn, index|
      lang = tcn.language.blank? ? '' : tcn.language.iso_639_1
      duplicate_check[lang] ||= []
      sorted_names[index] = nil if duplicate_check[lang].include?(tcn.name.string)
      duplicate_check[lang] << tcn.name.string
      name_languages[tcn.name.string] = lang
    end

    # now removing anything without a language if it exists with a language
    sorted_names.each_with_index do |tcn, index|
      next if tcn.nil?
      lang = tcn.language.blank? ? '' : tcn.language.iso_639_1
      sorted_names[index] = nil if lang.blank? && !name_languages[tcn.name.string].blank?
    end

    sorted_names.compact
  end

  # Return the curators who actually get credit for what they have done (for example, a new curator who hasn't done
  # anything yet doesn't get a citation).  Also, curators should only get credit on the pages they actually edited,
  # not all of it's children.  (For example.)
  def curators
    curator_activity_logs.collect{ |lcd| lcd.user }.uniq
  end
  alias :acting_curators :curators # deprecated.  TODO - remove entirely.

  def top_curators
    acting_curators[0..2]
  end
  alias :top_acting_curators :top_curators # deprecated.  TODO - remove entirely.

  def data_object_curators
    curators = connection.select_values("
      SELECT cal.user_id
      FROM #{CuratorActivityLog.database_name}.curator_activity_logs cal
      JOIN #{LoggingModel.database_name}.activities acts ON (cal.activity_id = acts.id)
      JOIN #{DataObject.full_table_name} do ON (cal.object_id = do.id)
      JOIN #{DataObject.full_table_name} do_all_versions ON (do.guid = do_all_versions.guid)
      JOIN #{DataObjectsTaxonConcept.full_table_name} dotc ON (do_all_versions.id = dotc.data_object_id)
      WHERE dotc.taxon_concept_id=#{self.id}
      AND cal.changeable_object_type_id IN(#{ChangeableObjectType.data_object_scope.join(",")})
      AND acts.id IN (#{Activity.raw_curator_action_ids.join(",")})").uniq
    User.find(curators)
  end

  # The International Union for Conservation of Nature keeps a status for most known species, representing how endangered that
  # species is.  This will default to "unknown" for species that are not being tracked.
  def iucn_conservation_status
    return iucn.description
  end

  # The scientific name for a TC will be italicized if it is a species (or below) and will include attribution and varieties, etc:
  def scientific_name(hierarchy = nil, italicize = true)
    hierarchy ||= Hierarchy.default
    quick_scientific_name(italicize && species_or_below? ? :italicized : :normal, hierarchy)
  end

  # Returns nucleotide sequences HE
  def nucleotide_sequences_hierarchy_entry_for_taxon
    @ncbi_entry ||= TaxonConcept.find_entry_in_hierarchy(self.id, Hierarchy.ncbi.id)
  end

  # Returns external links
  def content_partners_links
   return self.outlinks.sort_by { |ol| ol[:hierarchy_entry].hierarchy.label }
  end

  # Get a list of TaxonConcept models that are ancestors to this one.
  #
  # Note that TCs have no notion of ancestry in and of themselves, so they must defer to the hierarchy
  # entries to find ancestors. And, of course, that yields HierarchyEntry values, so we need to convert
  # them back.
  #
  # Also (IMPORTANT): there is another method called "ancestry", which, confusingly, returns HierarchyEntry
  # models, not TaxonConcept models.  Hmmmn.
  def ancestors
    return [] unless entry
    entry.ancestors.map {|a| a.taxon_concept }
  end

  # Get a list of TaxonConcept models that are children to this one.
  #
  # Same caveats as #ancestors (q.v.)
  def children
    return [] unless entry
    entry.children.map(&:taxon_concept)
  end

  # Call this instead of @current_user, so that you will be given the appropriate (and DRY) defaults.
  def current_user
    @current_user ||= User.new
  end

  def self.current_user_static
    @current_user ||= User.new
  end

  # Set the current user, so that methods will have defaults (language, etc) appropriate to that user.
  def current_user=(who)
    @images = nil
    @current_user = who
  end

  def canonical_form_object
    return nil unless entry
    return entry.canonical_form
  end

  # If *any* of the associated HEs are species or below, we consider this to be a species:
  def species_or_below?
    published_hierarchy_entries.detect {|he| he.species_or_below? }
  end

  def has_outlinks?
    return TaxonConcept.count_by_sql("SELECT 1
      FROM hierarchy_entries he
      JOIN hierarchies h ON (he.hierarchy_id = h.id)
      WHERE he.taxon_concept_id = #{self.id}
      AND he.published = 1
      AND he.visibility_id = #{Visibility.visible.id}
      AND h.browsable = 1
      AND (
        (he.source_url != '' AND he.source_url IS NOT NULL)
        OR (he.identifier != '' AND he.identifier IS NOT NULL AND h.outlink_uri != '' AND h.outlink_uri IS NOT NULL))
      LIMIT 1") > 0
  end

  def outlinks
    all_outlinks = []
    used_hierarchies = []
    entries_for_this_concept = HierarchyEntry.find_all_by_taxon_concept_id(id,
      :select => {
        :hierarchy_entries => [ :published, :visibility_id, :identifier, :source_url ],
        :hierarchies => [ :label, :outlink_uri, :url, :id ],
        :resources => [ :title, :id, :content_partner_id ],
        :content_partners => '*',
        :agents => [ :logo_cache_url, :full_name ],
        :collection_types => '*',
        :translated_collection_types => '*' },
      :include => { :hierarchy => [ { :resource => :content_partner }, :agent, { :collection_types => :translations }] })
    entries_for_this_concept.each do |he|
      next if used_hierarchies.include?(he.hierarchy)
      next if he.published != 1 && he.visibility_id != Visibility.visible.id
      if !he.source_url.blank?
        all_outlinks << {:hierarchy_entry => he, :hierarchy => he.hierarchy, :outlink_url => he.source_url }
        used_hierarchies << he.hierarchy
      elsif he.hierarchy && !he.hierarchy.outlink_uri.blank?
        # if the hierarchy outlink_uri expects an ID
        if matches = he.hierarchy.outlink_uri.match(/%%ID%%/)
          # .. and the ID exists
          unless he.identifier.blank?
            all_outlinks << {:hierarchy_entry => he, :hierarchy => he.hierarchy, :outlink_url => he.hierarchy.outlink_uri.gsub(/%%ID%%/, he.identifier) }
            used_hierarchies << he.hierarchy
          end
        else
          # there was no %%ID%% pattern in the outlink_uri, but its not blank so its a generic URL for all entries
          all_outlinks << {:hierarchy_entry => he, :hierarchy => he.hierarchy, :outlink_url => he.hierarchy.outlink_uri }
          used_hierarchies << he.hierarchy
        end
      end
    end

    # if the link is Wikipedia this will remove the revision ID
    all_outlinks.each do |ol|
      ol[:outlink_url].gsub!(/&oldid=[0-9]+$/, '')
    end

    return all_outlinks
  end

  def gbif_map_id
    return @gbif_map_id if @gbif_map_id
    if h = Hierarchy.gbif
      if he = HierarchyEntry.find_by_hierarchy_id_and_taxon_concept_id(h.id, self.id)
        @gbif_map_id = he.identifier
        return he.identifier
      end
    end
  end

  # Singleton method to fetch the Hierarchy Entry, used for taxonomic relationships
  def entry(hierarchy = nil)
    hierarchy ||= Hierarchy.default
    @cached_entry ||= {}
    return @cached_entry[hierarchy] if @cached_entry && @cached_entry[hierarchy]
    raise "Error finding default hierarchy" if hierarchy.nil? # EOLINFRASTRUCTURE-848
    raise "Cannot find a HierarchyEntry with anything but a Hierarchy" unless hierarchy.is_a? Hierarchy
    
    # return the cached one unless it is expired
    if taxon_concept_preferred_entry && taxon_concept_preferred_entry.hierarchy_entry &&
        !taxon_concept_preferred_entry.expired?
      return taxon_concept_preferred_entry.hierarchy_entry
    end
    
    TaxonConcept.preload_associations(self, :published_hierarchy_entries => [ :vetted, :hierarchy ])
    @all_entries ||= HierarchyEntry.sort_by_vetted(published_hierarchy_entries)
    if @all_entries.blank?
      @all_entries = HierarchyEntry.sort_by_vetted(hierarchy_entries)
    end

    best_entry ||= (@all_entries.detect{ |he| he.hierarchy_id == hierarchy.id } ||
      @all_entries[0] ||
      nil)
    
    if best_entry
      taxon_concept_preferred_entry.delete if taxon_concept_preferred_entry
      TaxonConceptPreferredEntry.create(:taxon_concept_id => self.id, :hierarchy_entry_id => best_entry.id)
    end
    @cached_entry[hierarchy] = best_entry
  end

  def entry_for_agent(agent_id)
    return nil if agent_id.blank? || agent_id == 0
    matches = hierarchy_entries.select{ |he| he.hierarchy && he.hierarchy.agent_id == agent_id }
    return nil if matches.empty?
    matches[0]
  end

  def self.entries_for_concepts(taxon_concept_ids, hierarchy = nil, strict_lookup = false)
    hierarchy ||= Hierarchy.default
    raise "Error finding default hierarchy" if hierarchy.nil? # EOLINFRASTRUCTURE-848
    raise "Cannot find a HierarchyEntry with anything but a Hierarchy" unless hierarchy.class.to_s == 'Hierarchy'
    raise "Must get an array of taxon_concept_ids" unless taxon_concept_ids.is_a? Array

    # get all hierarchy entries
    select = {:hierarchy_entries => '*', :vetted => :view_order}
    all_entries = HierarchyEntry.find_all_by_taxon_concept_id(taxon_concept_ids, :select => select, :include => :vetted)
    # ..and order them by published DESC, vetted view_order ASC, id ASC - earliest entry first
    all_entries = HierarchyEntry.sort_by_vetted(all_entries)

    concept_entries = {}
    all_entries.each do |he|
      concept_entries[he.taxon_concept_id] ||= []
      concept_entries[he.taxon_concept_id] << he
    end

    final_concept_entries = {}
    # we want ONLY the entry in this hierarchy
    if strict_lookup
      concept_entries.each do |taxon_concept_id, entries|
        final_concept_entries[taxon_concept_id] = entries.detect{ |he| he.hierarchy_id == hierarchy.id } || nil
      end
      return final_concept_entries
    end

    concept_entries.each do |taxon_concept_id, entries|
      final_concept_entries[taxon_concept_id] = entries.detect{ |he| he.hierarchy_id == hierarchy.id } || entries[0] || nil
    end
    return final_concept_entries
  end

  def self.ancestries_for_concepts(taxon_concept_ids, hierarchy = nil)
    return false if taxon_concept_ids.blank?
    concept_entries = self.entries_for_concepts(taxon_concept_ids, hierarchy)
    hierarchy_entry_ids = concept_entries.values.collect{|he| he.id || nil}.compact
    return false if hierarchy_entry_ids.blank?

    results = TaxonConcept.connection.execute("
        SELECT he.id, he.taxon_concept_id, n.string name_string, n_parent1.string parent_name_string, n_parent2.string grandparent_name_string
        FROM hierarchy_entries he
        JOIN names n ON (he.name_id=n.id)
        LEFT JOIN (
          hierarchy_entries he_parent1 JOIN names n_parent1 ON (he_parent1.name_id=n_parent1.id)
          LEFT JOIN (
            hierarchy_entries he_parent2 JOIN names n_parent2 ON (he_parent2.name_id=n_parent2.id)
          ) ON (he_parent1.parent_id=he_parent2.id)
        ) ON (he.parent_id=he_parent1.id)
        WHERE he.id IN (#{hierarchy_entry_ids.join(',')})").all_hashes

    ancestries = {}
    results.each do |r|
      r['name_string'] = r['name_string'].firstcap if r['name_string']
      r['parent_name_string'] = r['parent_name_string'].firstcap if r['parent_name_string']
      r['grandparent_name_string'] = r['grandparent_name_string'].firstcap if r['grandparent_name_string']
      ancestries[r['taxon_concept_id'].to_i] = r
    end
    return ancestries
  end

  def self.hierarchies_for_concepts(taxon_concept_ids, hierarchy = nil)
    return false if taxon_concept_ids.blank?
    concept_entries = self.entries_for_concepts(taxon_concept_ids, hierarchy)
    hierarchy_entry_ids = concept_entries.values.collect{|he| he.id || nil}.compact

    results = Hierarchy.find_by_sql("
        SELECT he.taxon_concept_id, h.*
        FROM hierarchy_entries he
        JOIN hierarchies h ON (he.hierarchy_id=h.id)
        WHERE he.id IN (#{hierarchy_entry_ids.join(',')})")

    hierarchies = {}
    results.each do |r|
      hierarchies[r['taxon_concept_id'].to_i] = r
    end
    return hierarchies
  end

  def entry_in_hierarchy(hierarchy)
    raise "Hierarchy does not exist" if hierarchy.nil?
    raise "Cannot find a HierarchyEntry with anything but a Hierarchy" unless hierarchy.is_a? Hierarchy
    return hierarchy_entries.detect{ |he| he.hierarchy_id == hierarchy.id } ||
      nil
  end

  # These are methods that are specific to a hierarchy, so we have to handle them through entry:
  # This was handled using delegate, before, but seemed to be causing problems, so I'm making it explicit:
  def kingdom(hierarchy = nil)
    h_entry = entry(hierarchy)
    return nil if h_entry.nil?
    return h_entry.kingdom(hierarchy)
  end

  def all_ancestor_taxon_concept_ids
    return @complete_ancestor_concept_ids if @complete_ancestor_concept_ids
    ancestor_concept_ids = TaxonConceptsFlattened.find_all_by_taxon_concept_id(id,
      :select => 'ancestor_id').collect{ |tcf| tcf.ancestor_id } + [id]
    @complete_ancestor_concept_ids = TaxonConceptsFlattened.find_all_by_taxon_concept_id(ancestor_concept_ids,
      :select => 'ancestor_id').collect{ |tcf| tcf.ancestor_id } + [id]
  end

  # general versions of the above methods for any hierarchy
  def find_ancestor_in_hierarchy(hierarchy)
    if he = published_hierarchy_entries.detect {|he| he.hierarchy_id == hierarchy.id }
      return he
    end
    published_hierarchy_entries.each do |entry|
      this_entry_in = entry.find_ancestor_in_hierarchy(hierarchy)
      return this_entry_in if this_entry_in
    end
    return nil
  end

  def in_hierarchy?(search_hierarchy = nil)
    return false unless search_hierarchy
    entries = published_hierarchy_entries.detect {|he| he.hierarchy_id == search_hierarchy.id }
    return entries.nil? ? false : true
  end

  def self.find_entry_in_hierarchy(taxon_concept_id, hierarchy_id)
    return HierarchyEntry.find_by_sql("SELECT he.* FROM hierarchy_entries he WHERE taxon_concept_id=#{taxon_concept_id} AND hierarchy_id=#{hierarchy_id} LIMIT 1").first
  end

  def has_map
    return true if gbif_map_id
  end

  def quick_common_name(language = nil, hierarchy = nil)
    language ||= current_user.language || Language.default
    hierarchy ||= Hierarchy.default
    common_name_results = connection.execute(
      "SELECT n.string name, he.hierarchy_id source_hierarchy_id
        FROM taxon_concept_names tcn
          JOIN names n ON (tcn.name_id = n.id)
          LEFT JOIN hierarchy_entries he ON (tcn.source_hierarchy_entry_id = he.id)
        WHERE tcn.taxon_concept_id=#{id} AND language_id=#{language.id} AND preferred=1"
    ).all_hashes

    final_name = ''

    # This loop is to check to make sure the default hierarchy's preferred name takes precedence over other hierarchy's preferred names
    common_name_results.each do |result|
      if final_name == '' || result['source_hierarchy_id'].to_i == hierarchy.id
        final_name = result['name'].firstcap
      end
    end
    return final_name
  end

  def quick_scientific_name(type = :normal, hierarchy = nil)
    hierarchy_entry = entry(hierarchy)
    # if hierarchy_entry is nil then this concept has no entries, and shouldn't be published
    return nil if hierarchy_entry.nil?

    search_type = case type
      when :italicized  then {:name_field => 'n.italicized', :also_join => ''}
      when :canonical   then {:name_field => 'cf.string',    :also_join => 'JOIN canonical_forms cf ON (n.canonical_form_id = cf.id)'}
      else                   {:name_field => 'n.string',     :also_join => ''}
    end

    scientific_name_results = connection.execute(
      "SELECT #{search_type[:name_field]} name, he.hierarchy_id source_hierarchy_id
       FROM hierarchy_entries he JOIN names n ON (he.name_id = n.id) #{search_type[:also_join]}
       WHERE he.id=#{hierarchy_entry.id}").all_hashes

    final_name = scientific_name_results[0]['name'].firstcap
    return final_name
  end
  alias :summary_name :quick_scientific_name


  def superceded_the_requested_id?
    @superceded_the_requested_id
  end

  def superceded_the_requested_id
    @superceded_the_requested_id = true
  end

  # Some TaxonConcepts are "superceded" by others, and we need to follow the chain (up to a sane limit):
  def self.find_with_supercedure(*args)
    concept = TaxonConcept.find_without_supercedure(*args)
    return nil if concept.nil?
    return concept unless concept.respond_to? :supercedure_id # sometimes it's an array.
    return concept if concept.supercedure_id == 0
    attempts = 0
    while concept.supercedure_id != 0 and attempts <= 6
      concept = TaxonConcept.find_without_supercedure(concept.supercedure_id)
      attempts += 1
    end
    concept.superceded_the_requested_id # Sets a flag that we can check later.
    return concept
  end
  class << self; alias_method_chain :find, :supercedure ; end

  def iucn
    return @iucn if !@iucn.nil?
    # IUCN was getting called over 240 times below, so I am checking the data_type
    # here rather than using the is_iucn? which would call DataType.iucn later in DataObject
    iucn_data_type = DataType.iucn
    
    iucn_objects = DataObject.find(:all, :joins => :data_objects_taxon_concepts,
      :conditions => "`data_objects_taxon_concepts`.`taxon_concept_id` = #{self.id}
        AND `data_objects`.`data_type_id` = #{DataType.iucn.id} AND `data_objects`.`published` = 1",
      :order => "`data_objects`.`id` DESC")
    my_iucn = iucn_objects.empty? ? nil : iucn_objects.first
    temp_iucn = my_iucn.nil? ? DataObject.new(:source_url => 'http://www.iucnredlist.org/about', :description => I18n.t(:not_evaluated)) : my_iucn
    @iucn = temp_iucn
    return @iucn
  end

  def iucn_conservation_status_url
    return iucn.source_url
  end

  # Returns an array of HierarchyEntry models (not TaxonConcept models), useful for building navigable
  # trees.  If you really want TCs, refer to #ancestors (yes, TODO - these sould be better-named!)
  def ancestry(hierarchy_id = nil)
    desired_entry = entry(hierarchy_id)
    return [] unless desired_entry
    return desired_entry.ancestors
  end

  def classifications
    hierarchy_entries.map do |entry|
      { :name => entry.hierarchy.agent.citable.display_string,
        :kingdom => entry.kingdom,
        :parent => entry.parent
      }
    end
  end

  def title(hierarchy = nil)
    return @title unless @title.nil?
    return '' if entry.nil?
    @title = entry.italicized_name.firstcap
  end

  def title_canonical(hierarchy = nil)
    return @title_canonical unless @title_canonical.nil?
    return '' if entry.nil?
    @title_canonical = entry.title_canonical
  end


  def subtitle(hierarchy = nil)
    return @subtitle unless @subtitle.nil?
    hierarchy ||= Hierarchy.default
    subtitle = quick_common_name(nil, hierarchy)
    subtitle = '' if subtitle.upcase == "[DATA MISSING]"
    @subtitle = subtitle
  end

  # comment on this
  def comment user, body
    comment = comments.create :user => user, :body => body
    user.comments.reload # be friendly - update the user's comments automatically
    comment
  end

  # This could use name... but I only need it for searches, and ID is all that matters, there.
  def <=>(other)
    return id <=> other.id
  end

  def related_names_count(related_names)
    if !related_names.blank?
      related_names_count = related_names['parents'].count
      related_names_count += related_names['children'].count
    else
      return 0
    end
  end

  def self.related_names(options = {})
    filter = []
    if !options[:taxon_concept_id].blank?
      filter << "he_child.taxon_concept_id=#{options[:taxon_concept_id]}"
      filter << "he_parent.taxon_concept_id=#{options[:taxon_concept_id]}"
    elsif !options[:hierarchy_entry_id].blank?
      filter << "he_child.id=#{options[:hierarchy_entry_id]}"
      filter << "he_parent.id=#{options[:hierarchy_entry_id]}"
    end

    parents = TaxonConcept.connection.execute("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, he_parent.taxon_concept_id, h.label hierarchy_label, he_parent.id hierarchy_entry_id
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (he_parent.name_id=n.id)
      JOIN hierarchies h ON (he_child.hierarchy_id=h.id)
      WHERE #{filter[0]}
      AND browsable=1
    ").all_hashes.uniq

    children = TaxonConcept.connection.execute("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, he_child.taxon_concept_id, h.label hierarchy_label, he_child.id hierarchy_entry_id
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (he_child.name_id=n.id)
      JOIN hierarchies h ON (he_parent.hierarchy_id=h.id)
      WHERE #{filter[1]}
      AND browsable=1
    ").all_hashes.uniq

    grouped_parents = {}
    for parent in parents
      key = parent['name_string'].downcase+"|"+parent['taxon_concept_id']
      grouped_parents[key] ||= {'taxon_concept_id' => parent['taxon_concept_id'], 'name_string' => parent['name_string'], 'sources' => [], 'hierarchy_entry_id' => parent['hierarchy_entry_id']}
      grouped_parents[key]['sources'] << parent
    end
    grouped_parents.each do |key, hash|
      hash['sources'].sort! {|a,b| a['hierarchy_label'] <=> b['hierarchy_label']}
    end
    grouped_parents = grouped_parents.sort {|a,b| a[0] <=> b[0]}

    grouped_children = {}
    for child in children
      key = child['name_string'].downcase+"|"+child['taxon_concept_id']
      grouped_children[key] ||= {'taxon_concept_id' => child['taxon_concept_id'], 'name_string' => child['name_string'], 'sources' => [],
        'hierarchy_entry_id' => child['hierarchy_entry_id']}
      grouped_children[key]['sources'] << child
    end
    grouped_children.each do |key, hash|
      hash['sources'].sort! {|a,b| a['hierarchy_label'] <=> b['hierarchy_label']}
    end
    grouped_children = grouped_children.sort {|a,b| a[0] <=> b[0]}

    combined = {'parents' => grouped_parents, 'children' => grouped_children}
  end

  def data_objects_for_api(options = {})
    # setting some default search options
    solr_search_params = {}
    solr_search_params[:sort_by] = 'status',
    solr_search_params[:visibility_types] = ['visible']
    solr_search_params[:skip_preload] = true
    if options[:licenses]
      if options[:licenses].include?('all')
        options[:licenses] = nil
      else
        options[:licenses] = options[:licenses].split("|").map do |l|
          l = 'public domain' if l == 'pd'
          l = 'not applicable' if l == 'na'
          License.find(:all, :conditions => "title REGEXP '^#{l}([^-]|$)'")
        end.flatten.compact
        solr_search_params[:license_ids] = options[:licenses].blank? ? nil : options[:licenses].collect(&:id)
      end
    end
    if options[:vetted] == "1"  # trusted
      solr_search_params[:vetted_types] = ['trusted']
    elsif options[:vetted] == "2"  # everything except untrusted
      solr_search_params[:vetted_types] = ['trusted', 'unreviewed']
    else
      solr_search_params[:vetted_types] = ['trusted', 'unreviewed', 'untrusted']
    end
    
    # GET THE TEXT
    text_objects = []
    if options[:text].to_i > 0
      options[:subjects] ||= 'TaxonBiology|GeneralDescription|Description'
      options[:text_subjects] = options[:subjects].split("|")
      options[:text_subjects] << 'Uses' if options[:text_subjects].include?('Use')
      if options[:text_subjects].include?('all')
        options[:text_subjects] = nil
      else
        options[:text_subjects] = options[:text_subjects].map{ |l| InfoItem.cached_find_translated(:label, l, 'en', :find_all => true) }.flatten.compact
        options[:toc_items] = options[:text_subjects].map{ |ii| ii.toc_item }.flatten.compact
      end
    
      text_objects = self.data_objects_from_solr(solr_search_params.merge({
        :per_page => options[:text].to_i,
        :toc_ids => options[:toc_items] ? options[:toc_items].collect(&:id) : nil,
        :data_type_ids => DataType.text_type_ids,
        :filter_by_subtype => false
      }))
      DataObject.preload_associations(text_objects, [ { :info_items => :translations } ] )
    end
    
    # GET THE IMAGES
    image_objects = []
    if options[:images].to_i > 0
      image_objects = self.data_objects_from_solr(solr_search_params.merge({
        :per_page => options[:images].to_i,
        :data_type_ids => DataType.image_type_ids,
        :return_hierarchically_aggregated_objects => true
      }))
    end
    
    # GET THE VIDEOS
    video_objects = []
    if options[:videos].to_i > 0
      video_objects = self.data_objects_from_solr(solr_search_params.merge({
        :per_page => options[:videos].to_i,
        :data_type_ids => DataType.video_type_ids,
        :return_hierarchically_aggregated_objects => true,
        :filter_by_subtype => false
      }))
      video_objects.each{ |d| d.data_type = DataType.video }
    end
    
    sound_objects = []
    if options[:sounds].to_i > 0
      sound_objects = self.data_objects_from_solr(solr_search_params.merge({
        :per_page => options[:sounds].to_i,
        :data_type_ids => DataType.sound_type_ids,
        :return_hierarchically_aggregated_objects => true,
        :filter_by_subtype => false
      }))
    end
    
    map_objects = []
    if options[:maps].to_i > 0
      map_objects = self.data_objects_from_solr(solr_search_params.merge({
        :per_page => options[:sounds].to_i,
        :data_type_ids => DataType.image_type_ids,
        :data_subtype_ids => DataType.map_type_ids
      }))
    end
    
    all_data_objects = [ text_objects, image_objects, video_objects, sound_objects, map_objects ].flatten.compact
    if options[:iucn] && options[:iucn] != "0"
      # we create fake IUCN objects if there isn't a real one. Don't use those in the API
      if iucn && iucn.id
        iucn.data_type = DataType.text
        all_data_objects << iucn
      end
    end
    
    # preload necessary associations for API response
    DataObject.preload_associations(all_data_objects, [ { :data_objects_hierarchy_entries => :vetted },
      :curated_data_objects_hierarchy_entries, :data_type, :license, :language, :mime_type,
      :users_data_object, { :agents_data_objects => [ :agent, :agent_role ] }, :published_refs ] )
    all_data_objects
  end

  def all_common_names
    common_names = []
    taxon_concept_names.each do |tcn|
      if tcn.vern == 1
        common_names << tcn.name
      end
    end
    common_names
  end

  # Unlike all_common_names, this method doesn't return language information.  In theory, they are all "scientific", anyway.
  def all_scientific_names
    Name.find_by_sql(['SELECT names.string
                         FROM taxon_concept_names tcn JOIN names ON (tcn.name_id = names.id)
                         WHERE tcn.taxon_concept_id = ? AND vern = 0', id])
  end

  def has_literature_references?
    Ref.literature_references_for?(self.id)
  end


  def add_common_name_synonym(name_string, options = {})
    agent     = options[:agent]
    preferred = !!options[:preferred]
    language  = options[:language] || Language.unknown
    vetted    = options[:vetted] || Vetted.unknown
    relation  = SynonymRelation.find_by_translated(:label, 'common name')
    name_obj  = Name.create_common_name(name_string)
    Synonym.generate_from_name(name_obj, :agent => agent, :preferred => preferred, :language => language,
                               :entry => entry, :relation => relation, :vetted => vetted)
  end

  def delete_common_name(taxon_concept_name)
    return if taxon_concept_name.blank?
    language_id = taxon_concept_name.language.id
    syn_id = taxon_concept_name.synonym.id
    Synonym.find(syn_id).destroy
  end

  def has_feed?
    feed_object = FeedDataObject.find_by_taxon_concept_id(self.id, :limit => 1)
    return !feed_object.blank?
  end

  # This needs to work on both TCNs and Synonyms.  Which, of course, smells like bad design, so.... TODO - review.
  def vet_common_name(options = {})
    vet_taxon_concept_names(options)
    vet_synonyms(options)
  end

  def self.supercede_by_ids(id1, id2)
    return false if id1 == id2
    return false if id1.class != Fixnum || id1.blank? || id1 == 0
    return false if id2.class != Fixnum || id2.blank? || id2 == 0


    # always ensure ID1 is the smaller of the two
    id1, id2 = id2, id1 if id2 < id1

    begin
      tc1 = TaxonConcept.find(id1)
      tc2 = TaxonConcept.find(id2)
    rescue
      return false
    end

    # at this point ID2 is the one going away
    # ID2 is being superceded by ID1
    TaxonConcept.connection.execute("UPDATE hierarchy_entries he JOIN taxon_concepts tc ON (he.taxon_concept_id=tc.id) SET he.taxon_concept_id=#{id1}, tc.supercedure_id=#{id1} WHERE taxon_concept_id=#{id2}");

    # all references to ID2 are getting changed to ID1
    TaxonConcept.connection.execute("UPDATE IGNORE taxon_concept_names SET taxon_concept_id=#{id1} WHERE taxon_concept_id=#{id2}");
    TaxonConcept.connection.execute("UPDATE IGNORE top_concept_images he SET taxon_concept_id=#{id1} WHERE taxon_concept_id=#{id2}");
    TaxonConcept.connection.execute("UPDATE IGNORE data_objects_taxon_concepts dotc SET taxon_concept_id=#{id1} WHERE taxon_concept_id=#{id2}");
    TaxonConcept.connection.execute("UPDATE IGNORE top_unpublished_concept_images he SET taxon_concept_id=#{id1} WHERE taxon_concept_id=#{id2}");
    TaxonConcept.connection.execute("UPDATE IGNORE hierarchy_entries he JOIN random_hierarchy_images rhi ON (he.id=rhi.hierarchy_entry_id) SET rhi.taxon_concept_id=he.taxon_concept_id WHERE he.taxon_concept_id=#{id2}");
    return true
  end

  def map_images(options ={})
    sounds = data_objects.find(:all, :conditions => "data_type_id IN (#{DataType.image_type_ids.join(',')}) AND
      data_subtype_id IN (#{DataType.map_type_ids.join(',')})")
  end

  def curated_hierarchy_entries
    published_hierarchy_entries.select do |he|
      he.hierarchy.browsable == 1 && he.published == 1 && he.visibility_id == Visibility.visible.id
    end
  end

  def top_communities
    # communities are sorted by the most number of members - descending order
    community_ids = communities.map{|c| c.id}.compact
    return [] if community_ids.blank?
    temp = connection.execute("SELECT c.id, COUNT(m.user_id) total FROM members m JOIN communities c ON c.id = m.community_id WHERE c.id in (#{community_ids.join(',')})   GROUP BY c.id ORDER BY total desc").all_hashes
    if temp.blank?
      return communities
    else
      communities_sorted_by_member_count = temp.map {|c| Community.find(c['id']) }
    end
    return communities_sorted_by_member_count[0..2]
  end

  def communities
    @communities ||= Community.find_by_sql("
      SELECT c.* FROM communities c
        JOIN collections_communities cc ON (cc.community_id = c.id)
        JOIN collections cl ON (cc.collection_id = cl.id)
        JOIN collection_items ci ON (ci.collection_id = cl.id)
      WHERE ci.object_id = #{id} AND object_type = 'TaxonConcept' AND c.published = 1
    ")
  end

  def top_collections
    return @top_collections if @top_collections
    all_containing_collections = collections.select{ |c| c.published? && !c.watch_collection? }
    # This algorithm (-relevance) was faster than either #reverse or rel * -1.
    @top_collections = all_containing_collections.sort_by { |c| [ -c.relevance ] }[0..2]
  end

  def flattened_ancestor_ids
    @flattened_ancestor_ids ||= flattened_ancestors.map {|a| a.ancestor_id }
  end

  def scientific_names_for_solr
    preferred_names = []
    synonyms = []
    surrogates = []
    return [] if published_hierarchy_entries.blank?
    published_hierarchy_entries.each do |he|
      if he.name.is_surrogate_or_hybrid?
        surrogates << he.name.string
      else
        preferred_names << he.name.string
        preferred_names << he.name.canonical_form.string if he.name.canonical_form
      end

      he.scientific_synonyms.each do |s|
        if s.name.is_surrogate_or_hybrid?
          surrogates << s.name.string
        else
          synonyms << s.name.string
          synonyms << s.name.canonical_form.string if s.name.canonical_form
        end
      end
    end

    return_keywords = []
    preferred_names = preferred_names.compact.uniq
    unless preferred_names.empty?
      return_keywords << { :keyword_type => 'PreferredScientific', :keywords => preferred_names, :ancestor_taxon_concept_id => flattened_ancestor_ids }
    end

    synonyms = synonyms.compact.uniq
    unless synonyms.empty?
      return_keywords << { :keyword_type => 'Synonym', :keywords => synonyms, :ancestor_taxon_concept_id => flattened_ancestor_ids }
    end

    surrogates = surrogates.compact.uniq
    unless surrogates.empty?
      return_keywords << { :keyword_type => 'Surrogate', :keywords => surrogates, :ancestor_taxon_concept_id => flattened_ancestor_ids }
    end

    return return_keywords
  end

  def common_names_for_solr
    common_names_by_language = {}
    unknowns = Language.all_unknowns
    published_hierarchy_entries.each do |he|
      he.common_names.each do |cn|
        vet_id = begin
                   cn.vetted_id
                 rescue # This seems to happen mostly during tests, but I figure it's best to be safe, anyway.
                   Synonym.find(cn).vetted_id
                 end
        next unless vet_id == Vetted.trusted.id || vet_id == Vetted.unknown.id # only Trusted or Unknown names go in
        next if cn.name.blank?
        # HE is sometimes being queried against an incomplete cache, so we reload it if needed:
        he = HierarchyEntry.find(he) unless he.attributes.keys.include?('published') && he.attributes.keys.include?('visibility_id')
        # only names from our curators, ubio, or from published and visible entries go in
        next unless ((he.published == 1 && he.visibility_id == Visibility.visible.id) || cn.hierarchy_id == Hierarchy.eol_contributors.id || cn.hierarchy_id == Hierarchy.ubio.id)
        next if unknowns.include? cn.language
        language = (cn.language_id!=0 && cn.language && !cn.language.iso_code.blank?) ? cn.language.iso_code : 'unknown'
        next if language == 'unknown' # we dont index names in unknown languages to cut down on noise
        common_names_by_language[language] ||= []
        common_names_by_language[language] << cn.name.string
      end
    end

    keywords = []
    common_names_by_language.each do |language, names|
      names = names.compact.uniq
      unless names.empty?
        keywords <<  { :keyword_type => 'CommonName', :keywords => names, :language => language, :ancestor_taxon_concept_id => flattened_ancestor_ids }
      end
    end
    return keywords
  end

  def media_count(user, selected_hierarchy_entry = nil)
    cache_key = "media_count_#{self.id}"
    cache_key += "_#{selected_hierarchy_entry.id}" if selected_hierarchy_entry && selected_hierarchy_entry.class == HierarchyEntry
    vetted_types = ['trusted', 'unreviewed']
    visibility_types = ['visible']
    if user && user.is_curator?
      cache_key += "_curator"
      vetted_types << 'untrusted'
      visibility_types << 'invisible'
    end
    @media_count ||= $CACHE.fetch(TaxonConcept.cached_name_for(cache_key), :expires_in => 1.days) do
      best_images = self.data_objects_from_solr({
        :per_page => 1,
        :data_type_ids => DataType.image_type_ids + DataType.video_type_ids + DataType.sound_type_ids,
        :vetted_types => vetted_types,
        :visibility_types => visibility_types,
        :ignore_translations => true,
        :filter_hierarchy_entry => selected_hierarchy_entry,
        :return_hierarchically_aggregated_objects => true
      }).total_entries
    end
  end

  def maps_count()
    @maps_count ||= $CACHE.fetch(TaxonConcept.cached_name_for("maps_count_#{self.id}"), :expires_in => 1.days) do
      count = self.data_objects_from_solr({
        :per_page => 1,
        :data_type_ids => DataType.image_type_ids,
        :data_subtype_ids => DataType.map_type_ids,
        :vetted_types => ['trusted', 'unreviewed'],
        :visibility_types => ['visible'],
        :ignore_translations => true
      }).total_entries
      count +=1 if self.has_map
      count
    end
  end

  # returns a DataObject, not a TaxonConceptExemplarImage
  def published_exemplar_image
    if concept_exemplar_image = taxon_concept_exemplar_image
      if the_best_image = concept_exemplar_image.data_object
        unless the_best_image.published?
          # best_image may end up being NIL, which means there is no published version
          # of it anymore - the example is no longer available. We don't want to show
          # unpublished exemplar images
          the_best_image = the_best_image.latest_published_version_in_same_language
        end
        return the_best_image
      end
    end
  end

  def exemplar_or_best_image_from_solr(selected_hierarchy_entry = nil)
    cache_key = "best_image_#{self.id}"
    cache_key += "_#{selected_hierarchy_entry.id}" if selected_hierarchy_entry && selected_hierarchy_entry.class == HierarchyEntry
    TaxonConceptExemplarImage
    CuratedDataObjectsHierarchyEntry
    DataObjectsHierarchyEntry
    ContentPartner
    AgentsDataObject
    AgentRole
    Agent
    UsersDataObject
    TocItem
    License
    @best_image ||= $CACHE.fetch(TaxonConcept.cached_name_for(cache_key), :expires_in => 1.days) do
      if published_exemplar = self.published_exemplar_image
        published_exemplar
      else
        best_images = self.data_objects_from_solr({
          :per_page => 1,
          :sort_by => 'status',
          :data_type_ids => DataType.image_type_ids,
          :vetted_types => ['trusted', 'unreviewed'],
          :visibility_types => ['visible'],
          :published => true,
          :skip_preload => true,
          :return_hierarchically_aggregated_objects => true,
          :filter_hierarchy_entry => selected_hierarchy_entry
        })
        (best_images.empty?) ? 'none' : best_images.first
      end
    end
    @best_image = nil if @best_image && (@best_image == 'none' || @best_image.published == 0)
    @best_image
  end

  def reset_instance_best_image_cache
    @best_image = nil
  end

  def images_from_solr(limit = 4, selected_hierarchy_entry = nil, ignore_translations = false)
    @images_from_solr ||= data_objects_from_solr({
      :per_page => limit,
      :sort_by => 'status',
      :data_type_ids => DataType.image_type_ids,
      :vetted_types => ['trusted', 'unreviewed'],
      :visibility_types => 'visible',
      :filter_hierarchy_entry => selected_hierarchy_entry,
      :ignore_translations => ignore_translations,
      :return_hierarchically_aggregated_objects => true
    })
  end
  
  def overview_text_for_user(the_user)
    overview_toc_item_ids = [TocItem.brief_summary, TocItem.comprehensive_description, TocItem.distribution].collect{ |toc_item| toc_item.id }
    overview_text_objects = self.text_for_user(the_user, {
      :per_page => 20,
      :language_ids => [ the_user.language.id ],
      :toc_ids => overview_toc_item_ids })
    DataObject.preload_associations(overview_text_objects, { :data_objects_hierarchy_entries => [ :hierarchy_entry,
      :vetted, :visibility ] },
      :select => {
        :data_objects_hierarchy_entries => '*',
        :hierarchy_entries => '*'
      })
    overview_text_objects = DataObject.sort_by_rating(overview_text_objects, self)
    overview_text_objects.first
  end
  
  # this just gets the TOCitems and their parents for the text given, sorted by view_order
  def table_of_contents_for_text(text_objects)
    toc_items_to_show = []
    text_objects.each do |obj|
      next unless obj.toc_items
      obj.toc_items.each do |toc_item|
        toc_items_to_show << toc_item
        if p = toc_item.parent
          toc_items_to_show << p
        end
      end
    end
    toc_items_to_show.compact!
    toc_items_to_show.uniq!
    toc_items_to_show.sort_by(&:view_order)
  end
  
  def has_details_text_for_user?(the_user)
    !details_text_for_user(the_user, :limit => 1, :skip_preload => true).empty?
  end
  
  # there is an artificial limit of 600 text objects here to increase the default 30
  def details_text_for_user(the_user, options = {})
    text_objects = self.text_for_user(the_user, {
      :language_ids => [ the_user.language.id ],
      :toc_ids_to_ignore => TocItem.exclude_from_details.collect{ |toc_item| toc_item.id },
      :per_page => (options[:limit] || 600) })
    
    # now preload info needed for display details metadata
    unless options[:skip_preload]
      selects = {
        :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
        :hierarchies => [ :id, :agent_id, :browsable, :outlink_uri, :label ],
        :data_objects_hierarchy_entries => '*',
        :curated_data_objects_hierarchy_entries => '*',
        :data_object_translations => '*',
        :table_of_contents => '*',
        :info_items => '*',
        :toc_items => '*',
        :translated_table_of_contents => '*',
        :users_data_objects => '*',
        :resources => '*',
        :content_partners => '*',
        :refs => '*',
        :ref_identifiers => '*',
        :comments => '*',
        :licenses => '*',
        :users_data_objects_ratings => '*' }
      DataObject.preload_associations(text_objects, [ :users_data_objects_ratings, :comments, :license,
        { :published_refs => :ref_identifiers }, :translations, :data_object_translation, { :toc_items => :info_items },
        { :data_objects_hierarchy_entries => [ { :hierarchy_entry => { :hierarchy => { :resource => :content_partner } } },
          :vetted, :visibility ] },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry }, :users_data_object,
        { :toc_items => [ :translations, [ :parent => :translations ] ] } ],
        :select => selects)
    end
    text_objects
  end
  
  def text_for_user(the_user = nil, options = {})
    vetted_types = ['trusted', 'unreviewed']
    visibility_types = ['visible']
    if the_user.class == User && the_user.is_curator?
      vetted_types << 'untrusted'
      visibility_types << 'invisible'
    end
    options[:per_page] ||= 500
    options[:data_type_ids] = DataType.text_type_ids
    options[:vetted_types] = vetted_types
    options[:visibility_types] = visibility_types
    options[:filter_by_subtype] = false
    self.data_objects_from_solr(options)
  end
  
  def data_objects_from_solr(solr_query_parameters = {})
    solr_query_parameters[:page] ||= 1  # return FIRST page by default
    solr_query_parameters[:per_page] ||= 30  # return 30 objects by default
    solr_query_parameters[:sort_by] ||= 'status'  # enumerated list defined in EOL::Solr::DataObjects
    solr_query_parameters[:data_type_ids] ||= nil  # return objects of ANY type by default
    unless solr_query_parameters.has_key?(:filter_by_subtype)
      solr_query_parameters[:filter_by_subtype] = true  # if this is true then we'll query using the data_subtype_id, even if its nil
    end
    solr_query_parameters[:data_subtype_ids] ||= nil  # return objects of ANY subtype by default - so this will include maps
    solr_query_parameters[:license_ids] ||= nil
    solr_query_parameters[:language_ids] ||= nil
    solr_query_parameters[:language_ids_to_ignore] ||= nil
    solr_query_parameters[:allow_nil_languages] ||= false  # true or false
    solr_query_parameters[:toc_ids] ||= nil
    solr_query_parameters[:toc_ids_to_ignore] ||= nil
    solr_query_parameters[:published] = true  # this can't be overridden - we always want published objects
    solr_query_parameters[:vetted_types] ||= ['trusted', 'unreviewed']  # labels are english strings simply because the SOLR fields use these labels
    solr_query_parameters[:visibility_types] ||= ['visible']  # labels are english strings simply because the SOLR fields use these labels
    solr_query_parameters[:filter_hierarchy_entry] ||= nil  # the entry in the concept when the user has the classification filter on
    solr_query_parameters[:ignore_translations] ||= false  # ignoring translations means we will not return objects which are translations of other original data objects
    solr_query_parameters[:return_hierarchically_aggregated_objects] ||= false  # if true, we will return images of ALL SPECIES of Animals for example
    solr_query_parameters[:skip_preload] ||= false  # if true, we will do less preload of associations
    
    # these are really only relevant to the worklist
    solr_query_parameters[:resource_id] ||= nil
    unless solr_query_parameters.has_key?(:curated_by_user)
      solr_query_parameters[:curated_by_user] = nil  # true, false or nil
    end
    unless solr_query_parameters.has_key?(:ignored_by_user)
      solr_query_parameters[:ignored_by_user] = nil  # true, false or nil
    end
    solr_query_parameters[:user] ||= nil
    solr_query_parameters[:facet_by_resource] ||= false  # this will add a facet parameter to the solr query
    EOL::Solr::DataObjects.search_with_pagination(self.id, solr_query_parameters)
  end

  def media_facet_counts
    @media_facet_counts ||= EOL::Solr::DataObjects.get_facet_counts(self.id)
  end

  def number_of_descendants
    connection.select_values("SELECT count(*) as count FROM taxon_concepts_flattened WHERE ancestor_id=#{self.id}")[0].to_i rescue 0
  end

  # These methods are defined in config/initializers, FWIW:
  def reindex_in_solr
    remove_from_index
    TaxonConcept.preload_associations(self, [
      { :published_hierarchy_entries => [ { :name => :canonical_form },
      { :scientific_synonyms => { :name => :canonical_form } },
      { :common_names => [ :name, :language ] } ] } ] )
    add_to_index
  end

private

  def vet_taxon_concept_names(options = {})
    raise "Missing :language_id" unless options[:language_id]
    raise "Missing :name_id" unless options[:name_id]
    raise "Missing :vetted" unless options[:vetted]

    taxon_concept_names_by_lang_id_and_name_id(options[:language_id], options[:name_id]).each do |tcn|
      tcn.vet(options[:vetted], current_user)
    end
  end

  def taxon_concept_names_by_lang_id_and_name_id(id_for_lang, id_for_name)
    TaxonConceptName.scoped(
      :conditions => ['taxon_concept_id = ? AND language_id = ? AND name_id = ?', id, id_for_lang, id_for_name]
    )
  end

  def vet_synonyms(options = {})
    hierarchy_entries.each do |he|
      he.vet_synonyms(options)
    end
  end
end

