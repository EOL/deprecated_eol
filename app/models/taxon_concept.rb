# Represents a group of HierarchyEntry instances that we consider "the same".
# This amounts to a vague idea of a taxon, which we serve as a single page.
#
# We get different interpretations of taxa from our partners (ContentPartner),
# often differing slightly and referring to basically the same thing, so
# TaxonConcept was created as a means to reconcile the variant definitions of
# what are essentially the same Taxon. We currently store basic Taxon we receive
# from data imports in the +hierarchy_entries+ table and we also store taxonomic
# hierarchies (HierarchyEntry) in the +hierarchy_entries+ table. Currently
# TaxonConcept are groups of one or many HierarchyEntry. We will eventually
# create hierarchy_entries for each entry in the taxa table (Taxon).
#
# It is worth mentioning that the "eol.org/pages/nnnn" route is a misnomer.
# Those IDs are, for the time-being, pointing to TaxonConcept, not pages.
#
# See the comments at the top of the Taxon for more information on this.  I
# include there a basic biological definition of what a Taxon is.

require 'eol/activity_loggable'

class TaxonConcept < ActiveRecord::Base
  include EOL::ActivityLoggable
  class << self ; include TaxonConcept::Cleanup ; end

  belongs_to :vetted

  attr_accessor :entries # TODO - this is used by DataObjectsController#add_association (and its partial) and probably shouldn't be.

  has_many :hierarchy_entries
  has_many :scientific_synonyms, through: :hierarchy_entries
  has_many :published_hierarchy_entries, class_name: HierarchyEntry.to_s,
    conditions: Proc.new { "hierarchy_entries.published=1 AND hierarchy_entries.visibility_id=#{Visibility.get_visible.id}" }
  has_many :top_concept_images
  has_many :top_unpublished_concept_images
  has_many :curator_activity_logs
  has_many :taxon_concept_names
  has_many :comments, as: :parent
  has_many :names, through: :taxon_concept_names
  has_many :ranks, through: :hierarchy_entries
  has_many :google_analytics_partner_taxa
  has_many :collection_items, as: :collected_item
  has_many :collections, through: :collection_items
  # TODO: this is just an alias of the above so all collectable entities have this association
  has_many :containing_collections, through: :collection_items, source: :collection
  has_many :published_containing_collections, through: :collection_items, source: :collection, conditions: 'published = 1',
    select: 'collections.id, collections.name, collections.collection_items_count, special_collection_id, relevance, logo_file_name, logo_cache_url',
    include: :communities
  has_many :preferred_names, class_name: "TaxonConceptName", conditions: 'taxon_concept_names.vern=0 AND taxon_concept_names.preferred=1'
  has_many :preferred_common_names, class_name: "TaxonConceptName", conditions: 'taxon_concept_names.vern=1 AND taxon_concept_names.preferred=1'
  has_many :denormalized_common_names, class_name: "TaxonConceptName", conditions: 'taxon_concept_names.vern=1'
  has_many :users_data_objects
  has_many :flattened_ancestors, class_name: "FlatTaxon"
  has_many :superceded_taxon_concepts, class_name: "TaxonConcept", foreign_key: "supercedure_id"
  has_many :taxon_data_exemplars

  has_one :page_json, inverse_of: :page, foreign_key: "page_id"
  has_one :taxon_classifications_lock
  has_one :taxon_concept_metric
  has_one :taxon_concept_exemplar_image
  has_one :taxon_concept_exemplar_article
  has_one :preferred_entry, class_name: 'TaxonConceptPreferredEntry'
  has_one :page_feature, inverse_of: :taxon_concept

  has_and_belongs_to_many :data_objects

  scope :published, -> { where(published: true) }
  scope :superceded, -> { where("supercedure_id != 0") }
  scope :trusted, -> { where(vetted_id: Vetted.trusted.id) }
  scope :unpublished, -> { where(published: false) }
  scope :unsuperceded, -> { where("supercedure_id = 0 OR "\
    "supercedure_id IS NULL") }
  # A bit of a cheat—we happen to know it will ONLY be unknown, not untrusted.
  scope :untrusted, -> { where(vetted_id: Vetted.unknown.id) }
  scope :with_title, -> { includes(preferred_entry: { hierarchy_entry:
    { name: [:ranked_canonical_form, :canonical_form] } }) }
  scope :with_subtitle, -> {
    includes(preferred_common_names: [:name, :language])
  }
  scope :with_titles, -> { with_title.with_subtitle }
  # This may seem redundant with :preferred_entry, but alas, it's a separate
  # query, so we need both:
  scope :with_hierarchies, -> {
    includes(published_hierarchy_entries: :hierarchy) }

  attr_accessor :common_names_in_language

  index_with_solr keywords: [ :scientific_names_for_solr, :common_names_for_solr ]

  def self.prepare_cache_classes
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
    Visibility
    Resource
    Vetted
    Hierarchy
    DataObject
  end

  def self.load_for_title_only(load_these)
    TaxonConcept.find(load_these, include: [:hierarchy_entries])
  end

  def self.default_solr_query_parameters(solr_query_parameters)
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
    solr_query_parameters[:ignore_translations] ||= false  # ignoring translations means we will not return objects which are translations of other original data objects
    solr_query_parameters[:return_hierarchically_aggregated_objects] ||= false  # if true, we will return images of ALL SPECIES of Animals for example

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
    return solr_query_parameters
  end

  # NOTE: this is used for site search summaries and collections only, ATM.
  def self.preload_for_shared_summary(taxon_concepts, options)
    includes = [
      { preferred_entry:
        { hierarchy_entry: [ { name: :ranked_canonical_form }, :hierarchy ] } },
      { taxon_concept_exemplar_image: { data_object:
        { data_objects_hierarchy_entries: [ :hierarchy_entry, :vetted, :visibility ] } } } ]
    TaxonConcept.preload_associations(taxon_concepts, includes)
    unless options[:skip_ancestry]
      he = taxon_concepts.collect do |tc|
        if tc.preferred_entry && ! tc.preferred_entry.hierarchy_entry.preferred_classification_summary?
          tc.preferred_entry.hierarchy_entry
        end
      end.flatten.compact
      HierarchyEntry.preload_associations(he, { flattened_ancestors: { ancestor: :name } } )
    end
    if options[:language_id] && ! options[:skip_common_names]
      # loading the names for the preferred common names in the user's language
      TaxonConcept.load_common_names_in_bulk(taxon_concepts, options[:language_id])
    end
  end

  # Some TaxonConcepts are "superceded" by others, and we need to follow the chain (up to a sane limit):
  def self.find_with_supercedure(*args)
    concept = TaxonConcept.find_without_supercedure(*args)
    return nil if concept.nil?
    return concept unless concept.respond_to? :supercedure_id # sometimes it's an array.
    return concept if concept.supercedure_id == 0
    attempts = 0
    while concept.supercedure_id != 0 and attempts <= 6 # TODO: Configurable
      concept = TaxonConcept.find_without_supercedure(concept.supercedure_id)
      attempts += 1
    end
    concept.superceded_the_requested_id # Sets a flag that we can check later.
    return concept
  end
  class << self; alias_method_chain :find, :supercedure ; end

  def superceded?
    !supercedure_id.nil? && supercedure_id != 0
  end

  def can_be_previewed_by?(user)
    return true if user.admin?
    entries = hierarchy_entries.
      includes(hierarchy: { resource: { content_partner: :user } })
    users = begin
      entries.map(&:hierarchy).map(&:resource).
        map(&:content_partner).map(&:user_id)
    rescue
      return false
    end
    users.include?(user.id)
  end

  def self.map_supercedure(ids)
    map = {}
    TaxonConcept.with_titles.unsuperceded.where(id: ids).each do |concept|
      map[concept.id] = concept
    end
    TaxonConcept.superceded.where(id: ids).map do |concept|
      maps_to = TaxonConcept.with_titles.find(concept.supercedure_id)
      map[concept.id] = maps_to unless maps_to.nil?
    end
    map
  end

  # this method is helpful when using preloaded taxon_concepts as preloading
  # will not use the above find_with_supercedure to get the latest version
  def latest_version
    if supercedure_id && supercedure_id != 0
      # using find will properly follow supercedureIDs
      return TaxonConcept.find(id)
    end
    self
  end

  def self.load_common_names_in_bulk(taxon_concepts, language_id)
    taxon_concepts_to_load = taxon_concepts.compact.select do |tc|
      tc.common_names_in_language ||= {}
      ! tc.common_names_in_language.has_key?(language_id)
    end
    names = Name.joins(:taxon_concept_names).
      where('taxon_concept_names.taxon_concept_id' => taxon_concepts_to_load.collect(&:id)).
      where("vern=1 AND preferred=1 AND language_id=#{language_id}").
      select('names.*, taxon_concept_id')
    taxon_concepts_to_load.each do |tc|
      tc.common_names_in_language[language_id] = names.detect{ |n| n.taxon_concept_id == tc.id }
    end
  end

  def self.merge_ids(id1, id2)
    TaxonConcept::Merger.ids(id1, id2)
  end

  def preferred_common_name_in_language(language = Language.default)
    if common_names_in_language && common_names_in_language.has_key?(language.id)
      # sometimes we preload preferred names in all languages for lots of taxa
      best_name_in_language = common_names_in_language[language.id]
    else
      # ...but if we don't, its faster to get only the one record in the current
      # language
      pref_name = if preferred_common_names.loaded?
        preferred_common_names.select { |pcn| pcn.language_id == language.id }
      else
        preferred_common_names.where(language_id: language.id)
      end
      if tcn = pref_name.first
        best_name_in_language = tcn.name
      end
    end
    if best_name_in_language
      return best_name_in_language.string.capitalize_all_words_if_language_safe
    end
  end

  def common_name(language = nil)
    language ||= Language.default
    preferred_common_name_in_language(language)
  end
  alias :subtitle :common_name

  def common_taxon_concept_name(language = nil)
    language ||= Language.default
    taxon_concept_names.preferred.where(language_id: language.id).first
  end

  # NOTE - this filters out results with no name, no language, languages with no
  # iso_639_1, and dulicates within the same language. Then it sorts the
  # results. TODO - rename it to make the filtering and sorting more clear.
  def common_names(options = {})
    @common_names = if options[:hierarchy_entry_id]
      TaxonConceptName.joins(:name, :language).where(source_hierarchy_entry_id: options[:hierarchy_entry_id])
    else
      taxon_concept_names.joins(:name, :language)
    end
    @common_names = @common_names.where("vern = 1 AND languages.iso_639_1 IS NOT NULL AND languages.iso_639_1 != ''").
      includes([ :language, :name ]).order('taxon_concept_names.language_id ASC, taxon_concept_names.preferred DESC')
    # remove duplicate names in the same language:
    duplicate_check = {}
    @common_names = @common_names.select do |tcn|
      key = "#{tcn.language.iso_639_1}:#{tcn.name.string}"
      keep = !duplicate_check[key]
      duplicate_check[key] = true
      keep
    end
    TaxonConceptName.sort_by_language_and_name(@common_names)
  end

  # Return the curators who actually get credit for what they have done (for
  # example, a new curator who hasn't done anything yet doesn't get a citation).
  # Also, curators should only get credit on the pages they actually edited, not
  # all of it's children.  (For example.)
  def curators
    curator_activity_logs.collect{ |lcd| lcd.user }.uniq
  end
  alias :acting_curators :curators # deprecated.  TODO - remove entirely.

  def top_curators
    acting_curators[0..2]
  end
  alias :top_acting_curators :top_curators # deprecated.  TODO - remove entirely.

  def data_object_curators
    curators = CuratorActivityLog.where(
      taxon_concept_id: id,
      changeable_object_type_id: (ChangeableObjectType.data_object_scope),
      activity_id: (Activity.raw_curator_action_ids)
    ).pluck(:user_id).uniq
    # using find_all_by_id instead of find because occasionally the user_id from activities is 0 and that causes this to fail
    User.find_all_by_id(curators)
  end

  # TODO - this should move to TaxonUserClassificationFilter or TaxonDetails or TaxonResources or something...
  # Returns nucleotide sequences HE
  def nucleotide_sequences_hierarchy_entry_for_taxon
    @ncbi_entry ||= HierarchyEntry.where("hierarchy_id = ? AND taxon_concept_id = ?", Hierarchy.ncbi.id, id).select(:identifier).first
  end

  # TODO - this should move to TaxonUserClassificationFilter or TaxonDetails or TaxonResources or something...
  def has_ligercat_entry?
    return nil unless Resource.ligercat && Resource.ligercat.hierarchy
    HierarchyEntry.where("hierarchy_id = ? AND taxon_concept_id = ?", Resource.ligercat.hierarchy.id, id).select(:identifier).first
  end

  # Returns external links
  def content_partners_links
   return self.outlinks.sort_by { |ol| ol[:hierarchy_entry].hierarchy.label }
  end

  # If *any* of the associated HEs are species or below, we consider this to be a species:
  def species_or_below?
    published_hierarchy_entries.detect { |he| he.species_or_below? } ? true : false
  end

  def outlinks
    all_outlinks = []
    entries_for_this_concept = HierarchyEntry.find_all_by_taxon_concept_id(id,
      select: {
        hierarchy_entries: [ :published, :visibility_id, :identifier, :source_url, :hierarchy_id ],
        hierarchies: [ :label, :outlink_uri, :url, :id ],
        resources: [ :title, :id, :content_partner_id ],
        content_partners: '*',
        agents: [ :logo_cache_url, :full_name ],
        collection_types: '*',
        translated_collection_types: '*' },
      include: { hierarchy: [ { resource: :content_partner }, :agent, { collection_types: :translations }]},
      conditions: "published = 1 AND visibility_id = #{Visibility.get_visible.id} AND vetted_id != #{Vetted.untrusted.id}",
      order: 'id DESC'
    )
    entries_for_this_concept.each do |he|
      next if all_outlinks.detect{ |o| o[:hierarchy_entry].hierarchy == he.hierarchy }
      if outlink_hash = he.outlink_hash
        all_outlinks << outlink_hash
      end
    end
    return all_outlinks
  end

  # Cleans up instance variables in addition to the usual lot.
  def reload
    TaxonConceptCacheClearing.clear(self) # NOTE - run this BEFORE clearing instance vars.
    clear_instance_variables
    super
  end

  def clear_instance_variables
    @@ar_instance_vars ||= TaxonConcept.new.instance_variables << :@mock_proxy # For tests
    (instance_variables - @@ar_instance_vars).each do |ivar|
      remove_instance_variable(ivar)
    end
  end

  def clear_for_data_object(data_object)
    TaxonConceptCacheClearing.clear_for_data_object(self, data_object)
  end

  # Singleton method to fetch the "best available" Hierarchy Entry and store that value.
  def entry(hierarchy = nil)
    @cached_entry ||= {}
    return @cached_entry[hierarchy] if @cached_entry[hierarchy]
    return preferred_entry.hierarchy_entry if preferred_entry_usable?(hierarchy)
    @all_entries ||= HierarchyEntry.sort_by_vetted(
      published_hierarchy_entries.includes(:vetted, :hierarchy))
    if @all_entries.blank?
      @all_entries = HierarchyEntry.sort_by_vetted(
        hierarchy_entries.includes(:vetted, :hierarchy))
    end
    best_entry = hierarchy ?
      @all_entries.detect { |he| he.hierarchy_id == hierarchy.id } || @all_entries.first :
      @all_entries.first
    create_preferred_entry(best_entry) if hierarchy.nil?
    @cached_entry[hierarchy] = best_entry
  end

  def entry_in_hierarchy(hierarchy)
    raise "Hierarchy does not exist" if hierarchy.nil?
    raise "Cannot find a HierarchyEntry with anything but a Hierarchy" unless hierarchy.is_a? Hierarchy
    return hierarchy_entries.detect{ |he| he.hierarchy_id == hierarchy.id } ||
      nil
  end

  def in_hierarchy?(search_hierarchy = nil)
    return false unless search_hierarchy
    entries = published_hierarchy_entries.detect { |he| he.hierarchy_id == search_hierarchy.id }
    return entries.nil? ? false : true
  end

  def superceded_the_requested_id?
    @superceded_the_requested_id
  end

  def superceded_the_requested_id
    @superceded_the_requested_id = true
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
      { name: entry.hierarchy.display_title,
        kingdom: entry.kingdom,
        parent: entry.parent
      }
    end
  end

  def rank_label
    entry.rank_label
  end

  # NOTE - the following name methods *attempt* to get what you're asking for. If such a thing isn't available, you
  # may get something different (ie: no attribution, no italics, etc).

  # TODO - these should be renamed to scientific_name, and #title should be an alias to this method on TaxonPage.
  # (There shouldn't be a "title" for a taxon_concept.)

  def title(hierarchy = nil)
    return @title unless @title.nil?
    return '' if entry(hierarchy).nil?
    @title = entry(hierarchy).italicized_name.firstcap
  end
  alias :summary_name :title
  alias :italicized_attributed_title :title

  def title_canonical(hierarchy = nil)
    return @title_canonical unless @title_canonical.nil?
    return '' if entry(hierarchy).nil?
    @title_canonical = entry(hierarchy).title_canonical
  end
  alias :non_italicized_unattributed_title :title_canonical
  alias :collected_name :title_canonical
  alias :canonical_form :title_canonical

  def title_canonical_italicized(hierarchy = nil)
    return @title_canonical_italicized unless @title_canonical_italicized.nil?
    return '' if entry(hierarchy).nil?
    @title_canonical_italicized = entry(hierarchy).title_canonical_italicized
  end
  alias :italicized_unattributed_title :title_canonical_italicized

  # NOTE - there is no non_italicized_attributed_title. You would never want one. Attribution implies proper
  # italicized form.

  def to_s
    "<TaxonConcept ##{id}: #{title_canonical}>"
  end

  def comment(user, body)
    comment = comments.create user: user, body: body
    user.comments.reload # be friendly - update the user's comments automatically
    comment
  end

  # This could use name... but I only need it for searches, and ID is all that matters, there.
  def <=>(other)
    return id <=> other.id
  end

  # NOTE - this is only used in the Solr API. This ignores the filters from #common_names, which removes duplicates
  # and common names that don't have a proper language. Thus, the Solr stores common names that won't show up on the
  # site. If this is a feature, it hasn't been expressed in comments yet.
  # TODO - I'm inclined to remove this method entirely and use #common_names for solr... or to at least comment on
  # the need for unfiltered names there...  OR (!) rename #common_names to
  # #uniq_common_names_with_no_missing_languages to express what's going on there, then rename this to
  # #common_name_strings
  def all_common_names
    taxon_concept_names.includes(:name).where(vern: 1).map { |tcn| tcn.name.string }
  end

  # TODO - see #all_common_names
  def all_scientific_names
    taxon_concept_names.includes(:name).where(vern: 0).map { |tcn| tcn.name.string }
  end

  def has_literature_references?
    Ref.literature_references_for?(self.id)
  end

  def add_common_name_synonym(name_string, options = {})
    TaxonConcept.with_master do
      agent     = options[:agent]
      preferred = !!options[:preferred]
      language  = options[:language] || Language.unknown
      vetted    = options[:vetted] || Vetted.unknown
      relation  = SynonymRelation.find_by_translated(:label, 'common name')
      name_obj  = Name.create_common_name(name_string)
      raise "Common name not created" unless name_obj
      Synonym.generate_from_name(name_obj, agent: agent, preferred: preferred,
        language: language, entry: entry, relation: relation, vetted: vetted)
    end
  end

  def delete_common_name(taxon_concept_name)
    return if taxon_concept_name.blank?
    language_id = taxon_concept_name.language.id
    syn_id = taxon_concept_name.synonym.id
    Synonym.find(syn_id).destroy
  end

  # This needs to work on both TCNs and Synonyms.  Which, of course, smells like
  # bad design, so.... TODO - review.
  def vet_common_name(options = {})
    vet_taxon_concept_names(options)
    vet_synonyms(options)
  end

  # TODO - this may belong on the TaxonOverview class (in modified form) and the
  # TaxonCommunities class, if we create one...
  def communities
    @communities ||= published_containing_collections.collect{ |c|
      c.communities.select{ |com| com.published? } }.flatten.compact.uniq
  end

  def flattened_ancestor_ids
    @flattened_ancestor_ids ||= flattened_ancestors.
      map { |a| a.ancestor_id }.sort.uniq
  end

  def scientific_names_for_solr
    preferred_names = []
    syns = []
    surrogates = []
    return [] if published_hierarchy_entries.blank?
    published_hierarchy_entries.each do |he|
      if he.name.is_surrogate_or_hybrid?
        surrogates << he.name.string
      else
        preferred_names << he.name.string
        preferred_names << he.title_canonical
      end

      he.scientific_synonyms.each do |s|
        if s.name.is_surrogate_or_hybrid?
          surrogates << s.name.string
        else
          syns << s.name.string
          syns << s.name.canonical_form.string if s.name.canonical_form
        end
      end
    end

    return_keywords = []
    preferred_names = preferred_names.compact.uniq
    unless preferred_names.empty?
      return_keywords << { keyword_type: 'PreferredScientific', keywords: preferred_names, ancestor_taxon_concept_id: flattened_ancestor_ids }
    end

    syns = syns.compact.uniq
    unless syns.empty?
      return_keywords << { keyword_type: 'Synonym', keywords: syns, ancestor_taxon_concept_id: flattened_ancestor_ids }
    end

    surrogates = surrogates.compact.uniq
    unless surrogates.empty?
      return_keywords << { keyword_type: 'Surrogate', keywords: surrogates, ancestor_taxon_concept_id: flattened_ancestor_ids }
    end

    return return_keywords
  end

  def common_names_for_solr
    common_names_by_language = {}
    common_names.each do |tcn|
      next unless [ Vetted.trusted.id, Vetted.unknown.id ].include?(tcn.vetted_id) # only Trusted or Unknown names go in
      next if tcn.name.blank?
      next if Language.all_unknowns.include?(tcn.language)
      language = (tcn.language_id != 0 && tcn.language && !tcn.language.iso_code.blank?) ? tcn.language.iso_code : 'unknown'
      next if language == 'unknown' # we dont index names in unknown languages to cut down on noise
      common_names_by_language[language] ||= []
      common_names_by_language[language] << tcn.name.string
    end

    keywords = []
    common_names_by_language.each do |language, names|
      names = names.compact.uniq
      unless names.empty?
        keywords <<  { keyword_type: 'CommonName', keywords: names, language: language, ancestor_taxon_concept_id: flattened_ancestor_ids }
      end
    end
    return keywords
  end

  # TODO - This should move to TaxonUserClassificationFilter, because it requires that information.
  def media_count(user, selected_hierarchy_entry = nil)
    @media_count ||= update_media_count(user: user, entry: selected_hierarchy_entry)
  end

  def map_json?
    @map_json ||= page_feature.try(:map_json?)
  end

  def maps_count
    # TODO - this method (and the next) could move to TaxonUserClassificationFilter... but I don't want to
    # move it because of this cache call. I think we should repurpose TaxonConceptCacheClearing to be
    # TaxonConceptCache, where we can handle both storing and clearing keys. That centralizes the logic,
    # and would allow us to put these two methods where they belong:
    @maps_count ||= Rails.cache.fetch(TaxonConcept.cached_name_for("maps_count_#{self.id}"), expires_in: 1.days) do
      count = get_one_map_from_solr.total_entries
      count +=1 if self.map_json?
      count
    end
  end

  def get_one_map_from_solr
    data_objects_from_solr(
      page: 1,
      per_page: 1,
      data_type_ids: DataType.image_type_ids,
      data_subtype_ids: DataType.map_type_ids,
      vetted_types: ['trusted', 'unreviewed'],
      visibility_types: ['visible'],
      ignore_translations: true,
    )
  end

  # returns a DataObject, not a TaxonConceptExemplarImage
  def published_exemplar_image
    return @published_exemplar_image if defined?(@published_exemplar_image)
    @published_exemplar_image = nil
    if concept_exemplar_image = taxon_concept_exemplar_image
      if the_best_image = concept_exemplar_image.data_object
        # NOTE - using if-not rather than unless because I think that's clearer with the elsif
        if ! the_best_image.published?
          # Someone has selected an exemplar image which is now unpublished. Remove it.
          concept_exemplar_image.destroy
        # TODO - we should have a DataObject#visible_for_taxon_concept?(tc) method.
        elsif the_best_image.visibility_by_taxon_concept(self).id == Visibility.get_visible.id
          the_best_image = the_best_image.latest_published_version_in_same_language
          @published_exemplar_image = the_best_image
        end
      end
    end
    @published_exemplar_image
  end

  # returns a DataObject, not a TaxonConceptExemplarArticle
  def published_visible_exemplar_article_in_language(language)
    return nil unless taxon_concept_exemplar_article
    if the_best_article = taxon_concept_exemplar_article.data_object.try(:latest_published_version_in_same_language)
      return nil if the_best_article.language != language
      return the_best_article if the_best_article.visibility_by_taxon_concept(self).id == Visibility.get_visible.id
    end
  end

  def exemplar_or_best_image_from_solr(selected_hierarchy_entry = nil)
    return @exemplar_or_best_image_from_solr if @exemplar_or_best_image_from_solr
    cache_key = "best_image_id_#{self.id}"
    if selected_hierarchy_entry && selected_hierarchy_entry.class == HierarchyEntry
      cache_key += "_#{selected_hierarchy_entry.id}"
    end
    TaxonConcept.prepare_cache_classes
    best_image_id ||= Rails.cache.fetch(TaxonConcept.cached_name_for(cache_key), expires_in: 1.days) do
      if published_exemplar_image
        published_exemplar_image.id
      else
        best_images = self.data_objects_from_solr({
          per_page: 1,
          sort_by: 'status',
          data_type_ids: DataType.image_type_ids,
          vetted_types: ['trusted', 'unreviewed'],
          visibility_types: ['visible'],
          published: true,
          return_hierarchically_aggregated_objects: true
        })
        # if for some reason we get back unpublished objects (Solr out of date), try to get the latest published versions
        unless best_images.empty?
          unless best_images.first.published?
            DataObject.replace_with_latest_versions!(best_images, select: [ :description ])
          end
        end
        (best_images.empty?) ? 'none' : best_images.first.id
      end
    end
    return nil if best_image_id == 'none'
    if @published_exemplar_image_calculated && @published_exemplar_image
      best_image = @published_exemplar_image
    else
      best_image = DataObject.fetch(best_image_id)
    end
    return nil unless best_image.published?
    @exemplar_or_best_image_from_solr = best_image
  end

  # NOTE - If you call #images_from_solr with two different sets of options, you will get the same
  # results on the second as with the first, so you only get one shot!
  def images_from_solr(limit = 4, options = {})
    @images_from_solr ||= data_objects_from_solr({
      per_page: limit,
      sort_by: 'status',
      data_type_ids: DataType.image_type_ids,
      vetted_types: ['trusted', 'unreviewed'],
      visibility_types: 'visible',
      ignore_translations: options[:ignore_translations] || false,
      return_hierarchically_aggregated_objects: true
    })
  end

  # TODO - this belongs in, at worst, TaxonPage... at best, TaxonOverview.
  # ...But the API is using this and I don't want to touch the API quite yet.
  def iucn
    return nil unless EolConfig.data?
    iucn_object = Rails.cache.fetch("pages/#{id}/iucn", expires_in: 2.weeks) do
      iucn_data = TraitBank.iucn_data(id)
      if iucn_data.nil?
        "" # Because you shouldn't cache nils...
      else
        DataObject.new(
          data_type: DataType.text,
          description: IucnStatus.from_uri(iucn_data[:status]),
          source_url: iucn_data[:source] )
      end
    end
    iucn_object == "" ? nil : iucn_object
  end

  # TODO: this belongs in, at worst, TaxonPage... at best, TaxonOverview
  # (though TaxonDetails needs access to the other method). ...But the API is
  # using this and I don't want to touch the API quite yet. TODO: stop passing
  # in a user, just a language. See #best_article_for_user and you'll see it
  # essentially ignores the user entirely anyway (with reason).
  def overview_text_for_user(the_user)
    @overview_text_for_user ||= {}
    return @overview_text_for_user[the_user.id] if the_user && @overview_text_for_user[the_user.id]
    the_user ||= EOL::AnonymousUser.new(Language.default)
    TaxonConcept.prepare_cache_classes
    cached_key = TaxonConcept.cached_name_for("best_article_id_#{id}_#{the_user.language_id}")
    best_article_id ||= Rails.cache.read(cached_key)
    return nil if best_article_id == 0 # Nothing's available, quickly move on...
    if best_article_id && DataObject.still_published?(best_article_id)
      article = DataObject.find(best_article_id)
      @overview_text_for_user[the_user.id] = article
      return article
    else
      article = best_article_for_user(the_user)
      expire_time = article.nil? ? 1.day : 1.week
      Rails.cache.fetch(cached_key, expires_in: expire_time) { article.nil? ? 0 : article.id }
      @overview_text_for_user[the_user.id] = article
      return article
    end
  end

  # TODO - this belongs in the same class as #overview_text_for_user. ...But be aware this is also used in TaxonDetails.
  def text_for_user(the_user = nil, options = {})
    the_user ||= EOL::AnonymousUser.new(Language.default)
    options[:per_page] ||= 500
    options[:data_type_ids] = DataType.text_type_ids
    options[:vetted_types] = the_user.vetted_types
    options[:visibility_types] = the_user.visibility_types
    options[:filter_by_subtype] ||= false
    self.data_objects_from_solr(options)
  end

  def data_objects_from_solr(solr_query_parameters = {})
    EOL::Solr::DataObjects.search_with_pagination(id, TaxonConcept.default_solr_query_parameters(solr_query_parameters))
  end

  def media_facet_counts
    @media_facet_counts ||= EOL::Solr::DataObjects.get_facet_counts(self.id)
  end

  def number_of_descendants
    FlatTaxon.descendants_of(id).count
  end

  def reindex
    reload
    reindex_in_solr
  end

  # These methods are defined in config/initializers, FWIW:
  def reindex_in_solr
    remove_from_index # TODO - shouldn't need this line; we remove in add_to_index
    TaxonConcept.preload_associations(self, [
      { published_hierarchy_entries: [ { name: :canonical_form },
      { scientific_synonyms: { name: :canonical_form } },
      { common_names: [ :name, :language ] } ] } ] )
    add_to_index
  end

  def uses_preferred_entry?(he)
    if preferred_entry.blank?
      if published_taxon_concept_preferred_entry
        # TODO - really? We want to *write* the preferred entry? Now? If so, rename this method.
        create_preferred_entry(published_taxon_concept_preferred_entry.hierarchy_entry)
      else
        return nil
      end
    end
    preferred_entry.hierarchy_entry_id == he.id &&
      CuratedTaxonConceptPreferredEntry.find_by_hierarchy_entry_id_and_taxon_concept_id(he.id, self.id)
  end

  # This does more than just loading the tcpe: it ensures the entry is there, valid, published, and finds
  # the "correct" version of it, if there are several. TODO - is it possible to do this with rails scopes?
  def published_taxon_concept_preferred_entry
    @published_taxon_concept_preferred_entry ||= CuratedTaxonConceptPreferredEntry.for_taxon_concept(self)
  end

  # Avoid re-loading the deep_published_hierarchy_entries from the DB:
  def cached_deep_published_hierarchy_entries
    @cached_deep_published_hierarchy_entries ||= hierarchy_entries.where('published=1').includes(:hierarchy).sort_by{ |he| he.hierarchy.label }
  end

  # Since the normal deep_published_hierarchy_entries association won't be sorted or pre-loaded:
  def deep_published_sorted_hierarchy_entries
    sort_and_preload_deeply_browsable_entries(cached_deep_published_hierarchy_entries)
  end

  # NOTE - this is only used by the API
  def published_sorted_hierarchy_entries_for_api
    entries = hierarchy_entries.where(hierarchy_id: Hierarchy.available_via_api.collect(&:id))
    HierarchyEntry.preload_associations(entries, [ :hierarchy, { name: :canonical_form }, :rank ])
    sort_and_preload_deeply_browsable_entries(entries)
  end

  # TODO - the next two methods call he.hierarchy.browsable ...is this loaded efficiently?

  # By default, we generally only want to expose *browsable* classifications.  This method finds those... unless a
  # curator has marked a non-browsable classification as the default (or there are no browsable classifications), in
  # which case we kind of have to show them all:
  def deep_published_browsable_hierarchy_entries
    return @deep_browsables if @deep_browsables
    current_entry_id = entry.id # Don't want to call #entry so many times...
    @deep_browsables = cached_deep_published_hierarchy_entries.dup
    @deep_browsables.delete_if { |he| current_entry_id != he.id && he.hierarchy.browsable.to_i == 0 }
    @deep_browsables += deep_published_browsable_hierarchy_entries if
      @deep_browsables.count == 1 && @deep_browsables.first.id == current_entry_id &&
        @deep_browsables.first.hierarchy.browsable.to_i == 0
    @deep_browsables.uniq!
    sort_and_preload_deeply_browsable_entries(@deep_browsables)
  end

  # Analog to #deep_published_browsable_hierarchy_entries, this simply grabs the non-browsable hierarchies... mostly
  # so we can count them, really... but there is no additional "cost" to loading them all, since we already have
  # them.
  def deep_published_nonbrowsable_hierarchy_entries
    return @deep_nonbrowsables if @deep_nonbrowsables
    current_entry_id = entry.try(:id)  # Don't want to call #entry so many times...
    @deep_nonbrowsables = cached_deep_published_hierarchy_entries.dup
    @deep_nonbrowsables.delete_if { |he| he.hierarchy.browsable.to_i == 1 || current_entry_id == he.id }
    HierarchyEntry.preload_deeply_browsable(@deep_nonbrowsables)
  end

  # Self-healing... nothing can be locked for more than 24 hours.
  def classifications_locked?
    if taxon_classifications_lock
      if taxon_classifications_lock.created_at <= 1.day.ago
        unlock_classifications
        return false
      end
      return true
    else
      return false
    end
  end

  def unlock_classifications
    taxon_classifications_lock.destroy if taxon_classifications_lock
  end

  def split_classifications(hierarchy_entry_ids, options = {})
    raise EOL::Exceptions::ClassificationsLocked if classifications_locked?
    disallow_large_curations
    lock_classifications
    ClassificationCuration.create(user: options[:user],
                                  hierarchy_entries: HierarchyEntry.find(hierarchy_entry_ids),
                                  source_id: id, exemplar_id: options[:exemplar_id])
  end

  def merge_classifications(hierarchy_entry_ids, options = {})
    source_concept = options[:with]
    raise EOL::Exceptions::ClassificationsLocked if
      classifications_locked? || source_concept.classifications_locked?
    if (!options[:forced]) && he_id = providers_match_on_merge(hierarchy_entry_ids)
      raise EOL::Exceptions::ProvidersMatchOnMerge.new(he_id)
    end
    raise EOL::Exceptions::CannotMergeClassificationsToSelf if self.id == source_concept.id
    disallow_large_curations
    source_concept.disallow_large_curations
    lock_classifications
    source_concept.lock_classifications
    ClassificationCuration.create(user: options[:user],
                                  hierarchy_entries: HierarchyEntry.find(hierarchy_entry_ids),
                                  source_id: source_concept.id,
                                  target_id: id, exemplar_id: options[:exemplar_id],
                                  forced: options[:forced] || options[:forced])
  end

  def all_published_entries?(hierarchy_entry_ids)
    hierarchy_entry_ids.map { |he| he.is_a?(HierarchyEntry) ? he.id : he.to_i }.compact.sort == deep_published_sorted_hierarchy_entries.map { |he| he.id}.compact.sort
  end

  def providers_match_on_merge(hierarchy_entry_ids)
    HierarchyEntry.select('hierarchy_entries.id, hierarchy_id, hierarchies.complete').joins(:hierarchy).
      where(hierarchy_entries: {id: hierarchy_entry_ids}).each do |he|
      break unless he.hierarchy.complete?
      hierarchy_entries.each do |my_he| # NOTE this is selecting the HEs ALREADY on this TC!
        # NOTE - error needs ENTRY id, not hierarchy id:
        return my_he.id if my_he.hierarchy_id == he.hierarchy_id && my_he.hierarchy.complete?
      end
    end
    return false
  end

  def published_browsable_hierarchy_entries
    published_hierarchy_entries.select { |he| he.hierarchy.browsable? }
  end

  def count_of_viewable_synonyms
    Synonym.where(hierarchy_entry_id: published_hierarchy_entries.collect(&:id)).where(
      "synonym_relation_id NOT IN (#{SynonymRelation.common_name_ids.join(',')})").count
  end

  def disallow_large_curations
    max_curatable_descendants = EolConfig.max_curatable_descendants rescue 25000
    raise EOL::Exceptions::TooManyDescendantsToCurate.new(number_of_descendants) if
      number_of_descendants > max_curatable_descendants.to_i
  end

  def lock_classifications
    TaxonClassificationsLock.find_or_create_by_taxon_concept_id(self.id)
  end

  def richness
    taxon_concept_metric.richness_score
  end

  def has_richness?
    taxon_concept_metric && !taxon_concept_metric.richness_score.blank?
  end

  def create_preferred_entry(entry)
    return if entry.nil?
    TaxonConceptPreferredEntry.with_master do
      # TODO - this *can* (and did, at least once) fail in a race condition. Perhaps it should be in a transaction. Also, I worry
      # that it is called too often. ...seems to be every page after every harvest, virtually. We should check on it.
      TaxonConceptPreferredEntry.destroy_all(taxon_concept_id: self.id)
      begin
        TaxonConceptPreferredEntry.create(taxon_concept_id: self.id, hierarchy_entry_id: entry.id)
      # NOTE: I realize rescuing without a specific exception is bad, but this
      # is a _rare_ error and I'm not sure what the exception type is.
      # Duplicate. ...Race condition?
      rescue => e
        logger.warn "Failed attempt to create preferred entry:"
        logger.warn "  -> Class: #{e.class.name}"
        logger.warn "  -> Message: #{e.message}"
      end
    end
  end

  # Public method, because we can do this from TaxonMedia:
  # TODO - This should move to TaxonUserClassificationFilter, because it requires that information.
  def update_media_count(options = {})
    selected_hierarchy_entry = options[:entry]
    cache_key = "media_count_#{self.id}"
    cache_key += "_#{selected_hierarchy_entry.id}" if selected_hierarchy_entry && selected_hierarchy_entry.class == HierarchyEntry
    if options[:user] && options[:user].is_curator?
      cache_key += "_curator"
    end
    Rails.cache.delete(TaxonConcept.cached_name_for(cache_key)) if options[:with_count]
    Rails.cache.fetch(TaxonConcept.cached_name_for(cache_key), expires_in: 1.days) do
      if options[:with_count]
        options[:with_count]
      else
        best_images = self.data_objects_from_solr({
          per_page: 1,
          data_type_ids: DataType.image_type_ids + DataType.video_type_ids + DataType.sound_type_ids,
          vetted_types: options[:user].vetted_types,
          visibility_types: options[:user].visibility_types,
          ignore_translations: true,
          return_hierarchically_aggregated_objects: true
        }).total_entries
      end
    end
  end

  def as_json(options = {})
    exemplar = exemplar_or_best_image_from_solr
    thumb = exemplar.nil? ? '' : exemplar.thumb_or_object('88_88')
    super(options.merge(except: [:split_from, :supercedure_id, :vetted_id])).merge(
      scientific_name: title,
      common_name: preferred_common_name_in_language(Language.default),
      thumbnail: thumb
    )
  end

  # TODO
  def should_show_clade_range_data
    return false
  end

  def wikipedia_entry
    if Hierarchy.wikipedia
      entry(Hierarchy.wikipedia)
    end
  end

  def self.get_entry_id_of_last_published_taxon
    taxon_concept_last = TaxonConcept.published.last unless TaxonConcept.published.blank?
    entry = taxon_concept_last.entry if taxon_concept_last
    entry ? entry.id : nil
  end

private

  # Assume this method is expensive.
  # TODO - this belongs in the same class as #overview_text_for_user
  def best_article_for_user(the_user)
    if published_exemplar = published_visible_exemplar_article_in_language(the_user.language)
      published_exemplar
    else
      # Sending User.new here since overview text should be the same for all users - curators
      # and admins should not see hidden text in the overview tab
      overview_text_objects = text_for_user(User.new, {
        per_page: 30,
        language_ids: the_user.language.all_ids,
        allow_nil_languages: (the_user.language.id == Language.default.id),
        toc_ids: TocItem.possible_overview_ids,
        filter_by_subtype: true })
      # TODO - really? #text_for_user returns unpublished articles?
      overview_text_objects.delete_if { |article| ! article.published? }
      DataObject.preload_associations(overview_text_objects, { data_objects_hierarchy_entries: [ :hierarchy_entry,
        :vetted, :visibility ] })
      return nil if overview_text_objects.empty?
      DataObject.sort_by_rating(overview_text_objects, self).first
    end
  end

  # Put the currently-preferred entry at the top of the list and load associations:
  def sort_and_preload_deeply_browsable_entries(set)
    current_entry_id = entry.id # Don't want to call #entry so many times...
    set.sort! { |a,b| a.id == current_entry_id ? -1 : b.id == current_entry_id ? 1 : 0}
    HierarchyEntry.preload_deeply_browsable(set)
  end

  def preferred_entry_usable?(hierarchy)
    if preferred_entry && preferred_entry.hierarchy_entry && !preferred_entry.expired?
      if hierarchy
        preferred_entry.hierarchy_entry.hierarchy_id == hierarchy.id
      else
        true
      end
    else
      false
    end
  end

  def vet_taxon_concept_names(options = {})
    raise "Missing :language_id" unless options[:language_id]
    raise "Missing :name_id" unless options[:name_id]
    raise "Missing :vetted" unless options[:vetted]
    raise "Missing :user" unless options[:user]

    taxon_concept_names_by_lang_id_and_name_id(options[:language_id], options[:name_id]).each do |tcn|
      tcn.vet(options[:vetted], options[:user])
    end
  end

  def taxon_concept_names_by_lang_id_and_name_id(id_for_lang, id_for_name)
    TaxonConceptName.scoped(
      conditions: ['taxon_concept_id = ? AND language_id = ? AND name_id = ?', id, id_for_lang, id_for_name]
    )
  end

  def vet_synonyms(options = {})
    hierarchy_entries.each do |he|
      he.vet_synonyms(options)
    end
  end

  def has_canonical_form?
    entry && entry.name && entry.name.canonical_form
  end

end
