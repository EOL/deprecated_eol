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
class TaxonConcept < SpeciesSchemaModel
  extend EOL::Solr::Search
  include ModelQueryHelper
  include EOL::Feedable

  #TODO belongs_to :taxon_concept_content
  belongs_to :vetted

  has_many :feed_data_objects
  has_many :hierarchy_entries
  has_many :published_hierarchy_entries, :class_name => HierarchyEntry.to_s,
    :conditions => 'hierarchy_entries.published=1 AND hierarchy_entries.visibility_id=#{Visibility.visible.id}'
  has_many :top_concept_images
  has_many :top_unpublished_concept_images
  has_many :last_curated_dates
  has_many :taxon_concept_names
  has_many :comments, :as => :parent
  has_many :names, :through => :taxon_concept_names
  has_many :ranks, :through => :hierarchy_entries
  has_many :google_analytics_partner_taxa
  has_many :collection_items, :as => :object
  has_many :preferred_names, :class_name => TaxonConceptName.to_s, :conditions => 'taxon_concept_names.vern=0 AND taxon_concept_names.preferred=1'
  has_many :preferred_common_names, :class_name => TaxonConceptName.to_s, :conditions => 'taxon_concept_names.vern=1 AND taxon_concept_names.preferred=1'
  has_many :synonyms, :class_name => Synonym.to_s, :foreign_key => 'hierarchy_entry_id',
    :finder_sql => 'SELECT s.* FROM #{Synonym.full_table_name} s JOIN #{HierarchyEntry.full_table_name} he ON (he.id = s.hierarchy_entry_id) WHERE he.taxon_concept_id=\'#{id}\' AND s.synonym_relation_id NOT IN (#{SynonymRelation.common_name_ids.join(",")})'
  has_many :users_data_objects
  has_many :flattened_ancestors, :class_name => TaxonConceptsFlattened.to_s
  has_many :all_data_objects, :class_name => DataObject.to_s, :finder_sql => '
      (SELECT do.id, do.data_type_id, do.vetted_id, do.visibility_id, do.published, do.guid, do.data_rating
        FROM data_objects_taxon_concepts dotc
        JOIN data_objects do ON (dotc.data_object_id=do.id)
          WHERE dotc.taxon_concept_id=#{id}
          AND do.data_type_id=#{DataType.image.id})
      UNION
      (SELECT do.id, do.data_type_id, do.vetted_id, do.visibility_id, do.published, do.guid, do.data_rating
        FROM top_concept_images tci
        JOIN data_objects do ON (tci.data_object_id=do.id)
          WHERE tci.taxon_concept_id=#{id})
      UNION
      (SELECT do.id, do.data_type_id, do.vetted_id, do.visibility_id, do.published, do.guid, do.data_rating
        FROM #{UsersDataObject.full_table_name} udo
        JOIN data_objects do ON (udo.data_object_id=do.id)
          WHERE udo.taxon_concept_id=#{id})'
  
  has_one :taxon_concept_content
  has_one :taxon_concept_metric
 
  has_and_belongs_to_many :data_objects

  has_many :superceded_taxon_concepts, :class_name => TaxonConcept.to_s, :foreign_key => "supercedure_id"


  attr_accessor :includes_unvetted # true or false indicating if this taxon concept has any unvetted/unknown data objects

  attr_reader :has_media, :length_of_images
  
  define_core_relationships :select => {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :names => :string,
      :vetted => :view_order,
      :canonical_forms => :string,
      :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating ],
      :licenses => :title,
      :table_of_contents => '*' },
    :include => [{ :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] }, { :data_objects => [ { :toc_items => :info_items }, :license] },
      { :users_data_objects => { :data_object => :toc_items } }]

  def show_curator_controls?(user = nil)
    return @show_curator_controls if !@show_curator_controls.nil?
    user = @current_user if user.nil?
    if user.nil?
      raise "a user must be specified"
    end
    @show_curator_controls = user.can_curate?(self)
    @show_curator_controls
  end

  def tocitem_for_new_text
    table_of_contents.each do |toc|
      return TocItem.find(toc.category_id) if toc.allow_user_text?
    end
    TocItem.find(:first, :joins => :info_items)
  end

  # The common name will defaut to the current user's language.
  def common_name(hierarchy = nil)
    quick_common_name(hierarchy)
  end

  def self.common_names_for_concepts(taxon_concept_ids, hierarchy = nil)
    quick_common_names(taxon_concept_ids, hierarchy)
  end

  def common_names
    TaxonConceptName.find_all_by_taxon_concept_id_and_vern(self.id, 1)
  end

  # Curators are those users who have special permission to "vet" data objects associated with a TC, and thus get
  # extra credit on their associated TC pages. This method returns an Array of those users.
  def curators(options={})
    return @curators unless @curators.nil?
    sel = { :users => [ :id, :username ] }
    users = User.find(:all,
      :select => sel,
        :joins => "JOIN #{HierarchyEntry.full_table_name} he ON (he.id = users.curator_hierarchy_entry_id)",
        :conditions => "he.taxon_concept_id IN (#{all_ancestor_taxon_concept_ids.join(',')})")
    @curators = users.uniq
  end

  # Return the curators who actually get credit for what they have done (for example, a new curator who hasn't done
  # anything yet doesn't get a citation).  Also, curators should only get credit on the pages they actually edited,
  # not all of it's children.  (For example.)
  def acting_curators
    last_curated_dates.collect{ |lcd| lcd.user }.uniq
  end

  # The International Union for Conservation of Nature keeps a status for most known species, representing how endangered that
  # species is.  This will default to "unknown" for species that are not being tracked.
  def iucn_conservation_status
    return iucn.description
  end

  # Returns true if the specified user has access to this TaxonConcept.
  def is_curatable_by? user
    return false unless user.curator_approved
    return false unless user.curator_hierarchy_entry_id
    curators.include?(user)
  end

  # Return a list of data objects associated with this TC's Overview toc (returns nil if it doesn't have one)
  def overview
    return text_objects_for_toc_item(TocItem.overview)
  end

  # The scientific name for a TC will be italicized if it is a species (or below) and will include attribution and varieties, etc:
  def scientific_name(hierarchy = nil, italicize = true)
    hierarchy ||= Hierarchy.default
    quick_scientific_name(italicize && species_or_below? ? :italicized : :normal, hierarchy)
  end

  # same as above but a static method expecting an array of IDs
  def self.scientific_names_for_concepts(taxon_concept_ids, hierarchy = nil)
    return false if taxon_concept_ids.blank?
    hierarchy ||= Hierarchy.default
    self.quick_scientific_names(taxon_concept_ids, hierarchy)
  end

  # pull list of categories for given taxon_concept_id
  def table_of_contents(options = {})
    if @table_of_contents.nil?
      tb = TocBuilder.new
      @table_of_contents = tb.toc_for(self, :agent => @current_agent, :user => current_user, :agent_logged_in => options[:agent_logged_in])
    end
    @table_of_contents
  end
  alias :toc :table_of_contents

  # If you just call "comments", you are actually getting comments that should really be invisible.  This method gets around this,
  # and didn't see appropriate to do with a named_scpope:
  def visible_comments(user = @current_user)
    return comments if user and user.is_moderator?
    comments.find_all {|comment| comment.visible? }
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

  # Get a list of some of our best TaxonConcept examples.  Results will be sorted by scientific name.
  #
  # The sorting is actually a moderately expensive operation, so this is cached.
  #
  # Lastly, note that the TaxonConcept IDs are hard-coded to our production database. TODO - move those IDs to a
  # table somewhere.
  #
  # EXEMPLARS THAT WE NO LONGER TRUST: 482935, 
  def self.exemplars(options = {})
    cached('exemplars') do
      TaxonConcept.lookup_exemplars(options)
    end
  end

  def self.lookup_exemplars(options = {})
    options[:language] ||= Language.english
    options[:size] ||= :medium
    exemplar_taxon_concept_ids = [910093, 1009706, 912371, 976559, 597748, 1061748, 373667, 392557,
      484592, 581125, 467045, 593213, 209984, 795869, 1049164, 604595, 983558,
      253397, 740699, 1044544, 683359, 1194666]
    exemplar_hashes = SpeciesSchemaModel.connection.select_all("
      SELECT rhi.taxon_concept_id, rhi.name scientific_name, n.string common_name, do.object_cache_url
        FROM random_hierarchy_images rhi
        JOIN data_objects do ON (rhi.data_object_id=do.id)
        LEFT JOIN (
          taxon_concept_names tcn
          JOIN names n ON (tcn.name_id=n.id AND tcn.language_id=#{options[:language].id} AND tcn.preferred=1)
        ) ON (rhi.taxon_concept_id=tcn.taxon_concept_id)
      WHERE rhi.taxon_concept_id IN (#{exemplar_taxon_concept_ids.join(',')})
      AND rhi.hierarchy_id=#{Hierarchy.default.id}")

    used_concepts = {}
    exemplar_taxa = []
    exemplar_hashes.each do |ex|
      next if !used_concepts[ex['taxon_concept_id']].nil?
      ex['image_cache_path'] = DataObject.image_cache_path(ex['object_cache_url'], options[:size])
      exemplar_taxa << ex
      used_concepts[ex['taxon_concept_id']] = true
    end
    exemplar_taxa.sort_by {|ex| ex['scientific_name']}
  end

  # Call this instead of @current_user, so that you will be given the appropriate (and DRY) defaults.
  def current_user
    @current_user ||= User.create_new
  end

  def self.current_user_static
    @current_user ||= User.create_new
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
        :hierarchy_entries => [:published, :visibility_id, :identifier, :source_url],
        :hierarchies => [:label, :outlink_uri, :url],
        :resources => :title,
        :agents => [ :logo_cache_url, :full_name ],
        :collection_types => [ :parent_id ] },
      :include => { :hierarchy => [:resource, :agent, :collection_types] })
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

  def has_citation?
    return false
  end

  # TODO - I believe these methods are obsolete (the more_* methods)
  # TODO = $MAX_IMAGES_PER_PAGE really should BE an int.
  def more_images
    return @length_of_images > $MAX_IMAGES_PER_PAGE.to_i if @length_of_images
    return images.length > $MAX_IMAGES_PER_PAGE.to_i # This is expensive.  I hope you called #images first!
  end

  def more_videos 
    return @length_of_videos > $MAX_IMAGES_PER_PAGE.to_i if @length_of_videos
    return video_data_objects.length > $MAX_IMAGES_PER_PAGE.to_i # This is expensive.  I hope you called #videos first!
  end

  # Singleton method to fetch the Hierarchy Entry, used for taxonomic relationships
  def entry(hierarchy = nil, strict_lookup = false)
    hierarchy ||= Hierarchy.default
    raise "Error finding default hierarchy" if hierarchy.nil? # EOLINFRASTRUCTURE-848
    raise "Cannot find a HierarchyEntry with anything but a Hierarchy" unless hierarchy.is_a? Hierarchy

    @all_entries ||= HierarchyEntry.sort_by_vetted(published_hierarchy_entries)

    # we want ONLY the entry in this hierarchy
    if strict_lookup
      return @all_entries.detect{ |he| he.hierarchy_id == hierarchy.id } || nil
    end

    return @all_entries.detect{ |he| he.hierarchy_id == hierarchy.id } ||
      @all_entries[0] ||
      nil
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

    results = SpeciesSchemaModel.connection.execute("
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


  def test
    return nil
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

  # # general versions of the above methods for any hierarchy
  # def find_ancestor_in_hierarchy(hierarchy)
  #   entry_in_hierarchy = HierarchyEntry.find_by_taxon_concept_id_and_hierarchy_id(all_ancestor_taxon_concept_ids, hierarchy.id, :order => 'lft desc')
  # end
  
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

  # We do have some content that is specific to COL, so we need a method that will ALWAYS reference it:
  def col_entry
    return @col_entry unless @col_entry.nil?
    hierarchy_id = Hierarchy.default.id
    return @col_entry = published_hierarchy_entries.detect{ |he| he.hierarchy_id == hierarchy_id }
  end

  def current_agent=(agent)
    @images = nil
    @current_agent = agent
  end

  def has_images
    available_media if @has_media.nil?
    @has_media[:images]
  end

  def has_video
    available_media if @has_media.nil?
    @has_media[:video]
  end

  def show_video_tab
    # checks logged-in user and/or logged-in content partner and also considers the existence of un-published videos, if Video tab is to be displayed
    return (video_data_objects.length > 0 ? true : false)
  end

  def has_map
    available_media if @has_media.nil?
    @has_media[:map]
  end

  def available_media
    # This method disregards whether there is a logged-in user or none
    images = video = map = false
    published_hierarchy_entries.each do |entry|
        next if entry.hierarchies_content.blank?
        images = true if entry.hierarchies_content.image != 0 || entry.hierarchies_content.child_image != 0
        video = true if entry.hierarchies_content.flash != 0 || entry.hierarchies_content.youtube != 0
        break if images && video
    end
    map = true if gbif_map_id
    @has_media = {:images => images, :video => video, :map => map}
  end

  def has_name?
    return content_level != 0
  end

  def quick_common_name(language = nil, hierarchy = nil)
    language ||= current_user.language
    hierarchy ||= Hierarchy.default
    common_name_results = SpeciesSchemaModel.connection.execute("SELECT n.string name, he.hierarchy_id source_hierarchy_id FROM taxon_concept_names tcn JOIN names n ON (tcn.name_id = n.id) LEFT JOIN hierarchy_entries he ON (tcn.source_hierarchy_entry_id = he.id) WHERE tcn.taxon_concept_id=#{id} AND language_id=#{language.id} AND preferred=1").all_hashes

    final_name = ''

    # This loop is to check to make sure the default hierarchy's preferred name takes precedence over other hierarchy's preferred names 
    common_name_results.each do |result|
      if final_name == '' || result['source_hierarchy_id'].to_i == hierarchy.id
        final_name = result['name'].firstcap
      end
    end
    return final_name
  end

  def self.quick_common_names(taxon_concept_ids, language = nil, hierarchy = nil)
    return false if taxon_concept_ids.blank?
    language  ||= TaxonConcept.current_user_static.language 
    hierarchy ||= Hierarchy.default
    common_name_results = SpeciesSchemaModel.connection.execute("SELECT n.string name, he.hierarchy_id source_hierarchy_id, tcn.taxon_concept_id FROM taxon_concept_names tcn JOIN names n ON (tcn.name_id = n.id) LEFT JOIN hierarchy_entries he ON (tcn.source_hierarchy_entry_id = he.id) WHERE tcn.taxon_concept_id IN (#{taxon_concept_ids.join(',')}) AND language_id=#{language.id} AND preferred=1").all_hashes

    concept_names = {}
    taxon_concept_ids.each{|id| concept_names[id.to_i] = nil }
    common_name_results.each do |r|
      if concept_names[r['taxon_concept_id'].to_i].blank? || r['source_hierarchy_id'].to_i == hierarchy.id
        concept_names[r['taxon_concept_id'].to_i] = r['name'].firstcap
      end
    end
    return concept_names
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

    scientific_name_results = SpeciesSchemaModel.connection.execute(
      "SELECT #{search_type[:name_field]} name, he.hierarchy_id source_hierarchy_id
       FROM hierarchy_entries he JOIN names n ON (he.name_id = n.id) #{search_type[:also_join]}
       WHERE he.id=#{hierarchy_entry.id}").all_hashes

    final_name = scientific_name_results[0]['name'].firstcap
    return final_name
  end

  def self.quick_scientific_names(taxon_concept_ids, hierarchy = nil)
    concept_entries = self.entries_for_concepts(taxon_concept_ids, hierarchy)
    return nil if concept_entries.blank?

    hierarchy_entry_ids = concept_entries.values.collect{|he| he.id || nil}.compact
    scientific_name_results = SpeciesSchemaModel.connection.execute(
      "SELECT n.string name_string, n.italicized, he.hierarchy_id source_hierarchy_id, he.taxon_concept_id, he.rank_id
       FROM hierarchy_entries he LEFT JOIN names n ON (he.name_id = n.id)
       WHERE he.id IN (#{hierarchy_entry_ids.join(',')})").all_hashes

    concept_names = {}
    scientific_name_results.each do |r|
      if concept_names[r['taxon_concept_id'].to_i].blank?
        name_string = Rank.italicized_ids.include?(r['rank_id'].to_i) ? r['italicized'] : r['name_string']
        concept_names[r['taxon_concept_id'].to_i] = name_string.firstcap
      end
    end
    return concept_names
  end


  def superceded_the_requested_id?
    @superceded_the_requested_id
  end

  def superceded_the_requested_id
    @superceded_the_requested_id = true
  end
  # # Some TaxonConcepts are "superceded" by others, and we need to follow the chain (up to a sane limit): 
  # def self.find_with_supercedure(taxon_concept_id, level = 0)
  #   level += 1
  #   raise "Supercedure stack is 7 levels deep" if level == 7
  #   tc = TaxonConcept.find(taxon_concept_id)
  #   return tc if (tc.supercedure_id == 0 || tc == nil)
  #   self.find_with_supercedure(tc.supercedure_id, level)
  # end

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
    iucn_objects = data_objects.select{ |d| d.is_iucn? && d.published? }.sort_by{ |d| Invert(d.id) }
    my_iucn = iucn_objects.empty? ? nil : DataObject.find(iucn_objects[0].id, :select => 'description, source_url')
    
    temp_iucn = my_iucn.nil? ? DataObject.new(:source_url => 'http://www.iucnredlist.org/', :description => I18n.t("not_evaluated")) : my_iucn
    temp_iucn.instance_eval { def agent_url; return Agent.iucn.homepage; end }
    @iucn = temp_iucn
    return @iucn
  end

  def iucn_conservation_status_url
    return iucn.respond_to?(:agent_url) ? iucn.agent_url : iucn.source_url
  end

  # TODO - find refs to these and make them grab a hierarchy...
  def current_node(hierarchy_id = nil)
    return entry(hierarchy_id)
  end

  # Returns an array of HierarchyEntry models (not TaxonConcept models), useful for building navigable
  # trees.  If you really want TCs, refer to #ancestors (yes, TODO - these sould be better-named!)
  def ancestry(hierarchy_id = nil)
    desired_entry = entry(hierarchy_id)
    return [] unless desired_entry
    return desired_entry.ancestors
  end

  def classification_attribution(hierarchy = nil)
    hierarchy ||= Hierarchy.default
    e = entry(hierarchy)
    return '' unless e
    return e.classification_attribution
  end

  # This may throw an ActiveRecord::RecordNotFound exception if the TocItem's category_id doesn't exist.
  def content_by_category(category_id, options = {})
    toc_item = TocItem.find(category_id) # Note: this "just works" even if category_id *is* a TocItem.
    ccb = CategoryContentBuilder.new
    if ccb.can_handle?(toc_item)
      ccb.content_for(toc_item, :vetted => current_user.vetted, :taxon_concept => self)
    else
      get_default_content(toc_item)
    end
  end

  def images(options = {})
    # set hierarchy to filter images by
    if self.current_user.filter_content_by_hierarchy && self.current_user.default_hierarchy_valid?
      filter_hierarchy = Hierarchy.find(self.current_user.default_hierarchy_id)
    else
      filter_hierarchy = nil
    end
    perform_filter = !filter_hierarchy.nil?
    
    image_page = (options[:image_page] ||= 1).to_i
    images = DataObject.images_for_taxon_concept(self, :user => self.current_user, :agent => @current_agent, :filter_by_hierarchy => perform_filter, :hierarchy => filter_hierarchy, :image_page => image_page)
    @length_of_images = images.length # Caching this because the call to #images is expensive and we don't want to do it twice.

    return images
  end

  def image_count
    count = @length_of_images || images.length # Note, no options... we want to count ALL images that this user can see.
    count = "#{$IMAGE_LIMIT}+" if count >= $IMAGE_LIMIT
    return count
  end

  # title and sub-title depend on expertise level of the user that is passed in (default to novice if none specified)
  def title(hierarchy = nil)
    return @title unless @title.nil?
    return '' if entry.nil?
    @title = entry.italicized_name.firstcap
  end

  def subtitle(hierarchy = nil)
    return @subtitle unless @subtitle.nil?
    hierarchy ||= Hierarchy.default
    subtitle = quick_common_name(nil, hierarchy)
    #subtitle = quick_scientific_name(:canonical, hierarchy) if subtitle.empty?  # no longer showing the canonical form
    subtitle = '' if subtitle.upcase == "[DATA MISSING]"
    subtitle = "<i>#{subtitle}</i>" unless subtitle.empty? or subtitle =~ /<i>/
    @subtitle = subtitle
  end

  def smart_thumb
    return images.blank? ? nil : images[0].smart_thumb
  end

  def smart_medium_thumb
    return images.blank? ? nil : images[0].smart_medium_thumb
  end

  def smart_image
    return images.blank? ? nil : images[0].smart_image
  end

  # comment on this
  def comment user, body
    comment = comments.create :user => user, :body => body
    user.comments.reload # be friendly - update the user's comments automatically
    comment
  end

  def content_level
    taxon_concept_content.content_level
  end

  # Gets an Array of TaxonConcept given DataObjects or their IDs
  #
  # this goes data_objects => data_objects_taxa => taxa => hierarchy_entries => taxon_concepts
  def self.from_data_objects *objects_or_ids
    ids = objects_or_ids.map {|o| if   o.is_a? DataObject 
                                  then o.id 
                                  else o.to_i end }
    return [] if ids.nil? or ids.empty? # Fix for EOLINFRASTRUCTURE-808
    sql = "SELECT tc.*
    FROM taxon_concepts tc
    JOIN hierarchy_entries he ON (tc.id = he.taxon_concept_id)
    JOIN data_objects_hierarchy_entries dohe ON (dohe.hierarchy_entry_id = he.id)
    JOIN data_objects do ON (do.id = dohe.data_object_id)
    WHERE do.id IN (#{ ids.join(', ') }) 
      AND tc.supercedure_id = 0
      AND tc.published = 1"
    TaxonConcept.find_by_sql(sql).uniq
  end

  def self.from_taxon_concepts(taxon_concept_ids,page) 
    if(taxon_concept_ids.length > 0) then
    query="Select taxon_concepts.id taxon_concept_id, taxon_concepts.supercedure_id, taxon_concepts.published, vetted.label vetted_label
    From taxon_concepts
    Inner Join vetted ON taxon_concepts.vetted_id = vetted.id
    WHERE taxon_concepts.id IN (#{ taxon_concept_ids.join(', ') })"
    self.paginate_by_sql [query, taxon_concept_ids], :page => page, :per_page => 20 , :order => 'id'
    end
  end

  # This could use name... but I only need it for searches, and ID is all that matters, there.
  def <=>(other)
    return id <=> other.id
  end

  def self.related_names(taxon_concept_id)
    parents = SpeciesSchemaModel.connection.execute("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, he_parent.taxon_concept_id, h.label hierarchy_label
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (he_parent.name_id=n.id)
      JOIN hierarchies h ON (he_child.hierarchy_id=h.id)
      WHERE he_child.taxon_concept_id=#{taxon_concept_id}
      AND browsable=1
    ").all_hashes.uniq

    children = SpeciesSchemaModel.connection.execute("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, he_child.taxon_concept_id, h.label hierarchy_label
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (he_child.name_id=n.id)
      JOIN hierarchies h ON (he_parent.hierarchy_id=h.id)
      WHERE he_parent.taxon_concept_id=#{taxon_concept_id}
      AND browsable=1
    ").all_hashes.uniq

    grouped_parents = {}
    for parent in parents
      key = parent['name_string'].downcase+"|"+parent['taxon_concept_id']
      grouped_parents[key] ||= {'taxon_concept_id' => parent['taxon_concept_id'], 'name_string' => parent['name_string'], 'sources' => []}
      grouped_parents[key]['sources'] << parent
    end
    grouped_parents.each do |key, hash|
      hash['sources'].sort! {|a,b| a['hierarchy_label'] <=> b['hierarchy_label']}
    end
    grouped_parents = grouped_parents.sort {|a,b| a[0] <=> b[0]}

    grouped_children = {}
    for child in children
      key = child['name_string'].downcase+"|"+child['taxon_concept_id']
      grouped_children[key] ||= {'taxon_concept_id' => child['taxon_concept_id'], 'name_string' => child['name_string'], 'sources' => []}
      grouped_children[key]['sources'] << child
    end
    grouped_children.each do |key, hash|
      hash['sources'].sort! {|a,b| a['hierarchy_label'] <=> b['hierarchy_label']}
    end
    grouped_children = grouped_children.sort {|a,b| a[0] <=> b[0]}

    combined = {'parents' => grouped_parents, 'children' => grouped_children}
  end

  def data_objects_for_api(options = {})
    options[:images] ||= 3
    options[:videos] ||= 1
    options[:text] ||= 1
    if options[:subjects]
      options[:text_subjects] = options[:subjects].split("|")
    else
      options[:text_subjects] = ['TaxonBiology', 'GeneralDescription', 'Description']
    end
    # create an alias Uses for Use (it was misspelled somewhere)
    if options[:text_subjects].include?('Use')
      options[:text_subjects] << 'Uses'
    end
    if options[:text_subjects].include?('all')
      options[:text_subjects] = nil
    else
      options[:text_subjects].map!{ |l| InfoItem.find_by_translated(:label, l) }.compact
    end
    if options[:licenses]
      if options[:licenses].include?('all')
        options[:licenses] = nil
      else
        options[:licenses] = options[:licenses].split("|").map do |l|
          l = 'public domain' if l == 'pd'
          l = 'not applicable' if l == 'na'
          License.find(:all, :conditions => "title like '#{l}%'")
        end.flatten.compact
      end
    end
    if options[:vetted] == "1"  # trusted
      options[:vetted] = [Vetted.trusted]
    elsif options[:vetted] == "2"  # everything except untrusted
      options[:vetted] = [Vetted.trusted, Vetted.unknown]
    else
      options[:vetted] = nil
    end
    
    return_data_objects = []
    # get the images
    if options[:images].to_i > 0
      image_data_objects = top_concept_images.collect{ |tci| tci.data_object }.compact
      # remove non-matching vetted and license values
      image_data_objects.delete_if do |d|
        (options[:vetted] && !options[:vetted].include?(d.vetted)) ||
        (options[:licenses] && !options[:licenses].include?(d.license))
      end
      image_data_objects = image_data_objects.group_objects_by('guid')  # group by guid
      image_data_objects = DataObject.sort_by_rating(image_data_objects)  # order by rating
      return_data_objects += image_data_objects[0...options[:images].to_i]  # get the # requested
    end
    
    # get the rest
    if options[:text].to_i > 0 || options[:videos].to_i
      non_image_objects = data_objects.select{ |d| !d.is_image? }
      non_image_objects.delete_if do |d|
        (options[:vetted] && !options[:vetted].include?(d.vetted)) ||
        (options[:licenses] && !options[:licenses].include?(d.license)) ||
        (d.is_text? && options[:text_subjects] && (options[:text_subjects] & d.info_items).empty?)
        # the use of & above is the array set intersection operator
      end
      non_image_objects = non_image_objects.group_objects_by('guid')  # group by guid
      non_image_objects = DataObject.sort_by_rating(non_image_objects)  # order by rating
      
      # remove items over the count limit
      types_count = {:text => 0, :video => 0}
      non_image_objects.each do |d|
        if d.is_text?
          types_count[:text] += 1
          return_data_objects << d if types_count[:text] <= options[:text].to_i
        elsif d.is_video?
          types_count[:video] += 1
          return_data_objects << d if types_count[:video] <= options[:videos].to_i
        end
      end
    end
    data_objects = DataObject.core_relationships.find_all_by_id(return_data_objects.collect{ |d| d.id })
    # set flash and youtube types to video, iucn to text
    data_objects.each do |d|
      d.data_type = DataType.video if d.is_video?
      d.data_type = DataType.text if d.is_iucn?
    end
    data_objects
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
  
  def has_stats?
    HierarchyEntryStat.count_by_sql("SELECT 1
      FROM hierarchy_entries he
      JOIN hierarchies h ON (he.hierarchy_id = h.id)
      JOIN hierarchy_entry_stats hes ON (he.id = hes.hierarchy_entry_id)
      WHERE he.taxon_concept_id = #{self.id}
      AND h.browsable = 1
      AND he.published = 1
      AND he.visibility_id = #{Visibility.visible.id}
      LIMIT 1") > 0
  end

  def has_related_names?
    entries_with_parents = published_hierarchy_entries.select{ |he| he.hierarchy.browsable && he.parent_id != 0 }
    return true unless entries_with_parents.empty?
    return TaxonConcept.count_by_sql("SELECT 1
                                      FROM hierarchy_entries he
                                      JOIN hierarchy_entries he_children ON (he.id=he_children.parent_id)
                                      JOIN hierarchies h ON (he_children.hierarchy_id=h.id)
                                      WHERE he.taxon_concept_id=#{id}
                                      AND h.browsable=1
                                      AND he_children.published=1
                                      LIMIT 1") > 0
  end

  def has_synonyms?
    return TaxonConcept.count_by_sql("SELECT 1
      FROM hierarchy_entries he
      JOIN hierarchies h ON (he.hierarchy_id = h.id)
      JOIN synonyms s ON (he.id = s.hierarchy_entry_id)
      WHERE he.taxon_concept_id = #{self.id}
      AND he.published = 1
      AND h.browsable = 1
      AND s.synonym_relation_id NOT IN (#{SynonymRelation.common_name_ids.join(',')})
      LIMIT 1") > 0
  end

  def has_common_names?
    return TaxonConcept.count_by_sql("SELECT 1
      FROM hierarchy_entries he
      JOIN hierarchies h ON (he.hierarchy_id = h.id)
      JOIN synonyms s ON (he.id = s.hierarchy_entry_id)
      WHERE he.taxon_concept_id = #{self.id}
      AND he.published = 1
      AND h.browsable = 1
      AND s.synonym_relation_id IN (#{SynonymRelation.common_name_ids.join(',')})
      LIMIT 1") > 0
  end
  
  def has_literature_references?
    Ref.literature_references_for?(self.id)
  end
  

  def add_common_name_synonym(name_string, options = {})
    agent     = options[:agent]
    preferred = !!options[:preferred]
    language  = options[:language] || Language.unknown
    vetted    = options[:vetted] || Vetted.unknown
    relation  = SynonymRelation.find_by_translated(:label, 'common name') # TODO - i18n
    name_obj  = Name.create_common_name(name_string)
    Synonym.generate_from_name(name_obj, :agent => agent, :preferred => preferred, :language => language,
                               :entry => entry, :relation => relation, :vetted => vetted)
  end

  def delete_common_name(taxon_concept_name)
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
  
  def text_toc_items_for_session(options={})
    this_toc_objects = data_objects.select{ |d| d.is_text? }
    user_objects = users_data_objects.select{ |udo| udo.data_object.is_text? }.collect{ |udo| udo.data_object}
    combined_objects = this_toc_objects | user_objects  # get the union of the two sets
    
    # this is a content partner, so we'll want o preload image contributors to prevent
    # a bunch of queries later on in DataObject.filter_list_for_user
    if options[:agent]
      DataObject.preload_associations(combined_objects,
        [ :hierarchy_entries => { :hierarchy => :agent } ],
        :select => {
          :hierarchy_entries => :hierarchy_id,
          :agents => :id } )
    end
    
    filtered_objects = DataObject.filter_list_for_user(combined_objects, :agent => options[:agent], :user => options[:user])
    return filtered_objects.collect{ |d| d.toc_items }.flatten.compact.uniq
  end
  
  def text_objects_for_toc_item(toc_item, options={})
    this_toc_objects = data_objects.select{ |d| d.toc_items && d.toc_items.include?(toc_item) }
    user_objects = users_data_objects.select{ |udo| udo.data_object.toc_items && udo.data_object.toc_items.include?(toc_item) }.
      collect{ |udo| udo.data_object}
    combined_objects = this_toc_objects | user_objects  # get the union of the two sets
    
    # remove objects this user shouldn't see
    filtered_objects = DataObject.filter_list_for_user(combined_objects, :agent => options[:agent], :user => options[:user])

    add_include = [:comments, :agents_data_objects, :info_items, :toc_items, { :users_data_objects => :user },
      { :published_refs => { :ref_identifiers => :ref_identifier_type } }, :all_comments]
    add_select = {
      :refs => '*',
      :ref_identifiers => '*',
      :ref_identifier_types => '*',
      :users => '*',
      :comments => [:parent_id, :visible_at] }

    objects = DataObject.core_relationships(:add_include => add_include, :add_select => add_select).
        find_all_by_id(filtered_objects.collect{ |d| d.id })
    if options[:user] && options[:user].is_curator? && options[:user].can_curate?(self)
      DataObject.preload_associations(objects, :users_data_objects_ratings, :conditions => "users_data_objects_ratings.user_id=#{options[:user].id}")
    end
    DataObject.sort_by_rating(objects)
  end
  
  def video_data_objects(options = {})
    usr = current_user
    if options[:unvetted]
      usr = current_user.clone
      usr.vetted = false
    end
    
    video_objects = data_objects.select{ |d| DataType.video_type_ids.include?(d.data_type_id) }
    filtered_objects = DataObject.filter_list_for_user(video_objects, :agent => @current_agent, :user => usr)
    
    add_include = [:agents_data_objects, :all_comments]
    add_select = { :comments => [:parent_id, :visible_at] }
    
    objects = DataObject.core_relationships(:add_include => add_include, :add_select => add_select).
        find_all_by_id(filtered_objects.collect{ |d| d.id })
    videos = DataObject.sort_by_rating(objects)
    @length_of_videos = videos.length # cached, so we don't have to query this again.
    return videos
  end
  
  def curated_hierarchy_entries
    published_hierarchy_entries.select do |he|
      he.hierarchy.browsable == 1 && he.published == 1 && he.visibility_id == Visibility.visible.id
    end
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

  def get_default_content(toc_item)
    result = {
      :content_type  => 'text',
      :category_name => toc_item.label,
      :data_objects  => text_objects_for_toc_item(toc_item, :agent => @current_agent, :user => current_user)
    }
    # TODO = this should not be hard-coded! IDEA = use partials.  Then we have variables and they can be dynamically changed.
    # NOTE: I tried to dynamically alter data_objects directly, below, but they didn't
    # "stick".  Thus, I override the array:
    override_data_objects = []
    result[:data_objects].each do |data_object|

      # override the object's description with the linked one if available
      data_object.description = data_object.description_linked if !data_object.description_linked.nil?

      if entry && data_object.sources.detect { |src| src.full_name == 'FishBase' }
        # TODO - We need a better way to choose which Agent to look at.  : \
        # TODO - We need a better way to choose which Collection to look at.  : \
        # TODO - We need a better way to choose which Mapping to look at.  : \
        foreign_key      = data_object.agents[0].collections[0].mappings[0].foreign_key
        (genus, species) = entry.name.canonical_form.string.split()
        data_object.fake_author(
          :full_name => 'See FishBase for additional references',
          :homepage  => "http://www.fishbase.org/References/SummaryRefList.cfm?ID=#{foreign_key}&GenusName=#{genus}&SpeciesName=#{species}",
          :logo_cache_url  => '')
      end
      override_data_objects << data_object
    end
    result[:data_objects] = override_data_objects
    return result
  end

end

