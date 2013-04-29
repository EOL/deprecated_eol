# Represents a group of HierarchyEntry instances that we consider "the same".  This amounts to a vague idea
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
require 'model_query_helper'
require 'eol/activity_loggable'

class TaxonConcept < ActiveRecord::Base
  include ModelQueryHelper
  include EOL::ActivityLoggable

  belongs_to :vetted

  attr_accessor :entries # TODO - this is used by DataObjectsController#add_association (and its partial) and probably shouldn't be.

  has_many :hierarchy_entries
  has_many :scientific_synonyms, :through => :hierarchy_entries
  has_many :published_hierarchy_entries, :class_name => HierarchyEntry.to_s,
    :conditions => Proc.new { "hierarchy_entries.published=1 AND hierarchy_entries.visibility_id=#{Visibility.visible.id}" }
  has_many :top_concept_images
  has_many :top_unpublished_concept_images
  has_many :curator_activity_logs
  has_many :taxon_concept_names
  has_many :comments, :as => :parent
  has_many :names, :through => :taxon_concept_names
  has_many :ranks, :through => :hierarchy_entries
  has_many :google_analytics_partner_taxa
  has_many :collection_items, :as => :collected_item
  has_many :collections, :through => :collection_items
  # TODO: this is just an alias of the above so all collectable entities have this association
  has_many :containing_collections, :through => :collection_items, :source => :collection
  has_many :preferred_names, :class_name => TaxonConceptName.to_s, :conditions => 'taxon_concept_names.vern=0 AND taxon_concept_names.preferred=1'
  has_many :preferred_common_names, :class_name => TaxonConceptName.to_s, :conditions => 'taxon_concept_names.vern=1 AND taxon_concept_names.preferred=1'
  has_many :denormalized_common_names, :class_name => TaxonConceptName.to_s, :conditions => 'taxon_concept_names.vern=1'
  has_many :users_data_objects
  has_many :flattened_ancestors, :class_name => TaxonConceptsFlattened.to_s
  has_many :superceded_taxon_concepts, :class_name => TaxonConcept.to_s, :foreign_key => "supercedure_id"

  has_one :taxon_classifications_lock
  has_one :taxon_concept_metric
  has_one :taxon_concept_exemplar_image
  has_one :taxon_concept_exemplar_article
  has_one :preferred_entry, :class_name => 'TaxonConceptPreferredEntry'
  has_one :curator_preferred_entry, :class_name => 'CuratedTaxonConceptPreferredEntry'

  has_and_belongs_to_many :data_objects

  attr_accessor :includes_unvetted # true or false indicating if this taxon concept has any unvetted/unknown data objects

  attr_reader :has_media, :length_of_images, :length_of_videos, :length_of_sounds

  index_with_solr :keywords => [ :scientific_names_for_solr, :common_names_for_solr ]

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
    TaxonConcept.find(load_these, :include => [:hierarchy_entries])
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
    return solr_query_parameters
  end
  
  def self.find_entry_in_hierarchy(taxon_concept_id, hierarchy_id)
    return HierarchyEntry.find_by_sql("SELECT he.* FROM hierarchy_entries he WHERE taxon_concept_id=#{taxon_concept_id} AND hierarchy_id=#{hierarchy_id} LIMIT 1").first
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

  # The common name will defaut to the current user's language.
  def common_name(hierarchy = nil)
    quick_common_name(hierarchy)
  end

  def preferred_common_name_in_language(language)
    if preferred_common_names.loaded?
      # sometimes we preload preferred names in all languages for lots of taxa
      best_name_in_language = preferred_common_names.detect { |c| c.language_id == language.id }
    else
      # ...but if we don't, its faster to get only the one record in the current language
      best_name_in_language = preferred_common_names.where("language_id = #{language.id}").first
    end
    if best_name_in_language
      return best_name_in_language.name.string.capitalize_all_words_if_language_safe
    end
  end

  # NOTE - this filters out results with no name, no language, languages with no iso_639_1, and dulicates within the
  # same language. Then it sorts the results. # TODO - rename it to make the filtering and sorting more clear.
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
      FROM #{CuratorActivityLog.full_table_name} cal
      JOIN #{Activity.full_table_name} acts ON (cal.activity_id = acts.id)
      JOIN #{DataObject.full_table_name} do ON (cal.target_id = do.id)
      JOIN #{DataObject.full_table_name} do_all_versions ON (do.guid = do_all_versions.guid)
      JOIN #{DataObjectsTaxonConcept.full_table_name} dotc ON (do_all_versions.id = dotc.data_object_id)
      WHERE dotc.taxon_concept_id=#{self.id}
      AND cal.changeable_object_type_id IN(#{ChangeableObjectType.data_object_scope.join(",")})
      AND acts.id IN (#{Activity.raw_curator_action_ids.join(",")})").uniq
    # using find_all_by_id instead of find because occasionally the user_id from activities is 0 and that causes this to fail
    User.find_all_by_id(curators)
  end

  # The scientific name for a TC will be italicized if it is a species (or below) and will include attribution and varieties, etc:
  # TODO - this is much slower than #title and should be removed.
  def scientific_name(hierarchy = nil, italicize = true)
    hierarchy ||= Hierarchy.default
    quick_scientific_name(italicize && species_or_below? ? :italicized : :normal, hierarchy)
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
    entry.ancestors.map { |a| a.taxon_concept }
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

  # Set the current user, so that methods will have defaults (language, etc) appropriate to that user.
  def current_user=(who)
    reload
    @current_user = who
  end

  # If *any* of the associated HEs are species or below, we consider this to be a species:
  def species_or_below?
    published_hierarchy_entries.detect { |he| he.species_or_below? }
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
        :hierarchy_entries => [ :published, :visibility_id, :identifier, :source_url, :hierarchy_id ],
        :hierarchies => [ :label, :outlink_uri, :url, :id ],
        :resources => [ :title, :id, :content_partner_id ],
        :content_partners => '*',
        :agents => [ :logo_cache_url, :full_name ],
        :collection_types => '*',
        :translated_collection_types => '*' },
      :include => { :hierarchy => [ { :resource => :content_partner }, :agent, { :collection_types => :translations }]},
      :conditions => "published = 1 and visibility_id = #{Visibility.visible.id}",
      :group => :hierarchy_id
    )
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

  # Cleans up instance variables in addition to the usual lot.
  def reload
    TaxonConceptCacheClearing.clear(self) # NOTE - run this BEFORE clearing instance vars.
    @@ar_instance_vars ||= TaxonConcept.new.instance_variables << :@mock_proxy # For tests
    (instance_variables - @@ar_instance_vars).each do |ivar|
      remove_instance_variable(ivar)
    end
    super
  end

  def clear_for_data_object(data_object)
    TaxonConceptCacheClearing.clear_for_data_object(self, data_object)
  end

  # Singleton method to fetch the "best available" Hierarchy Entry and store that value.
  def entry(hierarchy = nil)
    @cached_entry ||= {}
    return @cached_entry[hierarchy] if @cached_entry[hierarchy]
    raise "Cannot find a HierarchyEntry with anything but a Hierarchy" if hierarchy && !hierarchy.is_a?(Hierarchy)
    return preferred_entry.hierarchy_entry if preferred_entry_usable?(hierarchy)
    TaxonConcept.preload_associations(self, :published_hierarchy_entries => [ :vetted, :hierarchy ])
    @all_entries ||= HierarchyEntry.sort_by_vetted(published_hierarchy_entries)
    @all_entries = HierarchyEntry.sort_by_vetted(hierarchy_entries) if @all_entries.blank?
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

  def has_map?
    return true if (gbif_map_id && GbifIdentifiersWithMap.find_by_gbif_taxon_id(gbif_map_id))
  end

  def gbif_map_id
    return @gbif_map_id if @gbif_map_id
    if h = Hierarchy.gbif
      if he = HierarchyEntry.where("hierarchy_id = ? AND taxon_concept_id = ?", h.id, id).select(:identifier).first
        @gbif_map_id = he.identifier
        return he.identifier
      end
    end
  end

  # TODO - this is only used privately.
  def quick_common_name(language = nil, hierarchy = nil)
    language ||= current_user.language || Language.default
    hierarchy ||= Hierarchy.default
    common_name_results = connection.execute(
      "SELECT n.string name, he.hierarchy_id source_hierarchy_id
        FROM taxon_concept_names tcn
          JOIN names n ON (tcn.name_id = n.id)
          LEFT JOIN hierarchy_entries he ON (tcn.source_hierarchy_entry_id = he.id)
        WHERE tcn.taxon_concept_id=#{id} AND language_id=#{language.id} AND preferred=1"
    )

    final_name = ''

    # This loop is to check to make sure the default hierarchy's preferred name takes precedence over other hierarchy's preferred names
    common_name_results.each do |result|
      if final_name == '' || result[1].to_i == hierarchy.id
        final_name = result[0].firstcap
      end
    end
    return final_name
  end

  # TODO - #title is much (!) faster.  Can we get rid of this entirely?
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
       WHERE he.id=#{hierarchy_entry.id}")

    final_name = scientific_name_results.first.first.firstcap
    return final_name
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
      { :name => entry.hierarchy.display_title,
        :kingdom => entry.kingdom,
        :parent => entry.parent
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
  alias :italicized_attibuted_title :title

  def title_canonical(hierarchy = nil)
    return @title_canonical unless @title_canonical.nil?
    return '' if entry(hierarchy).nil?
    @title_canonical = entry(hierarchy).title_canonical
  end
  alias :non_italicized_unattributed_title :title_canonical
  alias :collected_name :title_canonical

  def title_canonical_italicized(hierarchy = nil)
    return @title_canonical_italicized unless @title_canonical_italicized.nil?
    return '' if entry(hierarchy).nil?
    @title_canonical_italicized = entry(hierarchy).title_canonical_italicized
  end
  alias :italicized_unattributed_title :title_canonical_italicized

  # NOTE - there is no non_italicized_attributed_title. You would never want one. Attribution implies proper
  # italicized form.

  def to_s
    "TaxonConcept ##{id}: #{title}"
  end

  # TODO - move to TaxonPage.
  def subtitle(hierarchy = nil)
    return @subtitle unless @subtitle.nil?
    hierarchy ||= Hierarchy.default
    subtitle = quick_common_name(nil, hierarchy)
    subtitle = '' if subtitle.upcase == "[DATA MISSING]"
    @subtitle = subtitle
  end

  # TODO - make a Commentable mixin
  def comment user, body
    comment = comments.create :user => user, :body => body
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

  # This needs to work on both TCNs and Synonyms.  Which, of course, smells like bad design, so.... TODO - review.
  def vet_common_name(options = {})
    vet_taxon_concept_names(options)
    vet_synonyms(options)
  end

  # NOTE - this is only used by the old API.
  def curated_hierarchy_entries
    published_hierarchy_entries.select do |he|
      he.hierarchy.browsable == 1 && he.published == 1 && he.visibility_id == Visibility.visible.id
    end
  end

  def communities
    @communities ||= containing_collections.where(:published => true).includes(:communities).collect{ |c|
      c.communities.select{ |com| com.published? } }.flatten.compact.uniq
  end

  def flattened_ancestor_ids
    @flattened_ancestor_ids ||= flattened_ancestors.map { |a| a.ancestor_id }
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
        preferred_names << he.name.canonical_form.string if he.name.canonical_form
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
      return_keywords << { :keyword_type => 'PreferredScientific', :keywords => preferred_names, :ancestor_taxon_concept_id => flattened_ancestor_ids }
    end

    syns = syns.compact.uniq
    unless syns.empty?
      return_keywords << { :keyword_type => 'Synonym', :keywords => syns, :ancestor_taxon_concept_id => flattened_ancestor_ids }
    end

    surrogates = surrogates.compact.uniq
    unless surrogates.empty?
      return_keywords << { :keyword_type => 'Surrogate', :keywords => surrogates, :ancestor_taxon_concept_id => flattened_ancestor_ids }
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
        keywords <<  { :keyword_type => 'CommonName', :keywords => names, :language => language, :ancestor_taxon_concept_id => flattened_ancestor_ids }
      end
    end
    return keywords
  end

  def media_count(user, selected_hierarchy_entry = nil)
    cache_key = "media_count_#{self.id}"
    cache_key += "_#{selected_hierarchy_entry.id}" if selected_hierarchy_entry && selected_hierarchy_entry.class == HierarchyEntry
    if user && user.is_curator?
      cache_key += "_curator"
    end
    @media_count ||= Rails.cache.fetch(TaxonConcept.cached_name_for(cache_key), :expires_in => 1.days) do
      best_images = self.data_objects_from_solr({
        :per_page => 1,
        :data_type_ids => DataType.image_type_ids + DataType.video_type_ids + DataType.sound_type_ids,
        :vetted_types => user.vetted_types,
        :visibility_types => user.visibility_types,
        :ignore_translations => true,
        :return_hierarchically_aggregated_objects => true
      }).total_entries
    end
  end

  def maps_count()
    # TODO - this method (and the next) could move to TaxonUserClassificationFilter... but I don't want to
    # move it because of this cache call. I think we should repurpose TaxonConceptCacheClearing to be 
    # TaxonConceptCache, where we can handle both storing and clearing keys. That centralizes the logic,
    # and would allow us to put these two methods where they belong:
    @maps_count ||= Rails.cache.fetch(TaxonConcept.cached_name_for("maps_count_#{self.id}"), :expires_in => 1.days) do
      count = get_one_map_from_solr.total_entries
      count +=1 if self.has_map?
      count
    end
  end

  def get_one_map_from_solr
    data_objects_from_solr(
      :page => 1, 
      :per_page => 1,
      :data_type_ids => DataType.image_type_ids,
      :data_subtype_ids => DataType.map_type_ids,
      :vetted_types => ['trusted', 'unreviewed'],
      :visibility_types => ['visible'],
      :ignore_translations => true,
      :skip_preload => true
    )
  end

  # returns a DataObject, not a TaxonConceptExemplarImage
  def published_exemplar_image
    return @published_exemplar_image if @published_exemplar_image_calculated # NOTE - weird, but ...
    @published_exemplar_image_calculated = true # NOTE ...since @published_exemplar_image can be nil, we need this.
    if concept_exemplar_image = taxon_concept_exemplar_image
      if the_best_image = concept_exemplar_image.data_object
        if the_best_image.visibility_by_taxon_concept(self).id == Visibility.visible.id
          unless the_best_image.published?
            # best_image may end up being NIL, which means there is no published version
            # of it anymore - the example is no longer available. We don't want to show
            # unpublished exemplar images
            the_best_image = the_best_image.latest_published_version_in_same_language
          end
          return @published_exemplar_image = the_best_image
        end
      end
    end
  end

  # returns a DataObject, not a TaxonConceptExemplarArticle
  def published_visible_exemplar_article_in_language(language)
    return nil unless taxon_concept_exemplar_article
    if the_best_article = taxon_concept_exemplar_article.data_object.latest_published_version_in_same_language
      return nil if the_best_article.language != language
      return the_best_article if the_best_article.visibility_by_taxon_concept(self).id == Visibility.visible.id
    end
  end

  def exemplar_or_best_image_from_solr(selected_hierarchy_entry = nil)
    cache_key = "best_image_id_#{self.id}"
    if selected_hierarchy_entry && selected_hierarchy_entry.class == HierarchyEntry
      cache_key += "_#{selected_hierarchy_entry.id}"
    end
    TaxonConcept.prepare_cache_classes
    best_image_id ||= Rails.cache.fetch(TaxonConcept.cached_name_for(cache_key), :expires_in => 1.days) do
      if published_exemplar_image
        published_exemplar_image.id
      else
        best_images = self.data_objects_from_solr({
          :per_page => 1,
          :sort_by => 'status',
          :data_type_ids => DataType.image_type_ids,
          :vetted_types => ['trusted', 'unreviewed'],
          :visibility_types => ['visible'],
          :published => true,
          :skip_preload => true,
          :return_hierarchically_aggregated_objects => true
        })
        # if for some reason we get back unpublished objects (Solr out of date), try to get the latest published versions
        unless best_images.empty?
          unless best_images.first.published?
            DataObject.replace_with_latest_versions!(best_images, :select => [ :description ])
          end
        end
        (best_images.empty?) ? 'none' : best_images.first.id
      end
    end
    return nil if best_image_id == 'none'
    best_image = DataObject.find(best_image_id)
    return nil unless best_image.published?
    best_image
  end

  # NOTE - If you call #images_from_solr with two different sets of options, you will get the same
  # results on the second as with the first, so you only get one shot!
  def images_from_solr(limit = 4, options = {})
    unless options[:skip_preload] == false
      options[:skip_preload] == true
      options[:preload_select] == { :data_objects => [ :id, :guid, :language_id, :data_type_id ] }
    end
    @images_from_solr ||= data_objects_from_solr({
      :per_page => limit,
      :sort_by => 'status',
      :data_type_ids => DataType.image_type_ids,
      :vetted_types => ['trusted', 'unreviewed'],
      :visibility_types => 'visible',
      :ignore_translations => options[:ignore_translations] || false,
      :return_hierarchically_aggregated_objects => true,
      :skip_preload => options[:skip_preload],
      :preload_select => options[:preload_select]
    })
  end

  # TODO - this belongs in, at worst, TaxonPage... at best, TaxonOverview. ...But the API is using this and I don't
  # want to touch the API quite yet.
  def iucn
    return @iucn if @iucn
    # TODO - rewrite query ... move to new class, perhaps?
    iucn_objects = DataObject.find(:all, :joins => :data_objects_taxon_concepts,
      :conditions => "`data_objects_taxon_concepts`.`taxon_concept_id` = #{id}
        AND `data_objects`.`data_type_id` = #{DataType.iucn.id} AND `data_objects`.`published` = 1",
      :order => "`data_objects`.`id` DESC")
    my_iucn = iucn_objects.empty? ? nil : iucn_objects.first
    @iucn = my_iucn.nil? ? DataObject.new(:source_url => 'http://www.iucnredlist.org/about', :description => I18n.t(:not_evaluated)) : my_iucn
  end

  # TODO - this belongs in, at worst, TaxonPage... at best, TaxonOverview. ...But the API is using this and I don't
  # want to touch the API quite yet.
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
      Rails.cache.fetch(cached_key, :expires_in => expire_time) { article.nil? ? 0 : article.id }
      @overview_text_for_user[the_user.id] = article
      return article
    end
  end
  
  # TODO - there may have been changes to #has_details_text_for_user? ...I need to check that and change the
  # TaxonPage class, if so.
  # TODO - this belongs in the same class as #overview_text_for_user.
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
    TaxonConceptsFlattened.descendants_of(id).count
  end

  def reindex
    reload
    reindex_in_solr
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

  def uses_preferred_entry?(he)
    if preferred_entry.blank?
      ctcpe = CuratedTaxonConceptPreferredEntry.find_by_taxon_concept_id(id)
      if ctcpe
        create_preferred_entry(ctcpe.hierarchy_entry)
      else
        return nil
      end
    end
    preferred_entry.hierarchy_entry_id == he.id &&
      CuratedTaxonConceptPreferredEntry.find_by_hierarchy_entry_id_and_taxon_concept_id(he.id, self.id) 
  end

  # Avoid re-loading the deep_published_hierarchy_entries from the DB:
  def cached_deep_published_hierarchy_entries
    @cached_deep_published_hierarchy_entries ||= hierarchy_entries.where('published=1').includes(:hierarchy).sort_by{ |he| he.hierarchy.label }
  end

  # Since the normal deep_published_hierarchy_entries association won't be sorted or pre-loaded:
  def deep_published_sorted_hierarchy_entries
    sort_and_preload_deeply_browsable_entries(cached_deep_published_hierarchy_entries)
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
    current_entry_id = entry.id  # Don't want to call #entry so many times...
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
    raise EOL::Exceptions::ClassificationsLocked if
      classifications_locked?
    disallow_large_curations
    lock_classifications
    ClassificationCuration.create(:user => options[:user],
                                  :hierarchy_entries => HierarchyEntry.find(hierarchy_entry_ids),
                                  :source_id => id, :exemplar_id => options[:exemplar_id])
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
    ClassificationCuration.create(:user => options[:user],
                                  :hierarchy_entries => HierarchyEntry.find(hierarchy_entry_ids),
                                  :source_id => source_concept.id,
                                  :target_id => id, :exemplar_id => options[:exemplar_id],
                                  :forced => options[:forced] || options[:forced])
  end

  def all_published_entries?(hierarchy_entry_ids)
    hierarchy_entry_ids.map { |he| he.is_a?(HierarchyEntry) ? he.id : he.to_i }.compact.sort == deep_published_sorted_hierarchy_entries.map { |he| he.id}.compact.sort
  end

  def providers_match_on_merge(hierarchy_entry_ids)
    HierarchyEntry.select('hierarchy_entries.id, hierarchy_id, hierarchies.complete').joins(:hierarchy).
      where(:hierarchy_entries => {:id => hierarchy_entry_ids}).each do |he|
      break unless he.hierarchy.complete?
      hierarchy_entries.each do |my_he| # NOTE this is selecting the HEs ALREADY on this TC!
        # NOTE - error needs ENTRY id, not hierarchy id:
        return my_he.id if my_he.hierarchy_id == he.hierarchy_id && my_he.hierarchy.complete?
      end
    end
    return false
  end
  
  def published_browsable_hierarchy_entries
    hierarchy_entries.joins(:hierarchy).where('hierarchy_entries.published=1 AND hierarchies.browsable=1')
  end
  
  def published_browsable_visible_hierarchy_entries
    hierarchy_entries.joins(:hierarchy).
      where("hierarchy_entries.published=1 AND hierarchy_entries.visibility_id=#{Visibility.visible.id} AND hierarchies.browsable=1")
  end
  
  def count_of_viewable_synonyms
    count = published_browsable_visible_hierarchy_entries.collect do |he|
      he.synonyms.where("synonyms.synonym_relation_id NOT IN (#{SynonymRelation.common_name_ids.join(',')})").count
    end.inject(:+)
    count ||= 0
    count
  end
  
  def all_data_objects
    DataObject.find_by_sql(
        "(SELECT do.id, do.data_type_id, do.published, do.guid, do.data_rating, do.language_id
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
            WHERE udo.taxon_concept_id=#{id})")
  end

  def disallow_large_curations
    max_curatable_descendants = SiteConfigurationOption.max_curatable_descendants rescue 10000
    raise EOL::Exceptions::TooManyDescendantsToCurate.new(number_of_descendants) if
      number_of_descendants > max_curatable_descendants
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
    TaxonConceptPreferredEntry.destroy_all(:taxon_concept_id => self.id)
    TaxonConceptPreferredEntry.create(:taxon_concept_id => self.id, :hierarchy_entry_id => entry.id)
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
        :per_page => 30,
        :language_ids => the_user.language.all_ids,
        :allow_nil_languages => (the_user.language.id == Language.default.id),
        :toc_ids => TocItem.possible_overview_ids,
        :filter_by_subtype => true })
      # TODO - really? #text_for_user returns unpublished articles?
      overview_text_objects.delete_if { |article| ! article.published? }
      DataObject.preload_associations(overview_text_objects, { :data_objects_hierarchy_entries => [ :hierarchy_entry,
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

  def has_canonical_form?
    entry && entry.name && entry.name.canonical_form
  end

end

