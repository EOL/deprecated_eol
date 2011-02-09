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

  #TODO belongs_to :taxon_concept_content
  belongs_to :vetted

  has_many :feed_data_objects
  has_many :hierarchy_entries
  has_many :top_concept_images
  has_many :top_unpublished_concept_images
  has_many :last_curated_dates
  has_many :taxon_concept_names
  has_many :comments, :as => :parent
  has_many :names, :through => :taxon_concept_names
  has_many :ranks, :through => :hierarchy_entries
  has_many :google_analytics_partner_taxa
  has_many :collection_items, :as => :object

  has_one :taxon_concept_content

  attr_accessor :includes_unvetted # true or false indicating if this taxon concept has any unvetted/unknown data objects

  attr_reader :has_media, :length_of_images

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
    TocItem.find_by_sql('SELECT t.id, t.parent_id, t.label, t.view_order
                         FROM table_of_contents t, info_items i
                         WHERE i.toc_id=t.id
                         LIMIT 1')[0]
  end

  # The canonical form is the simplest string we can use to identify a species--no variations, no attribution, nothing
  # fancy:
  def canonical_form
    return name(:canonical)
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
  def curators
    return @curators unless @curators.nil?
    users = User.find_all_by_curator_hierarchy_entry_id_and_curator_approved(all_ancestor_entry_ids, true, :include => {:curator_hierarchy_entry => :name_object})
    unless in_hierarchy?(Hierarchy.default)
      if entry_in_default = find_ancestor_in_hierarchy(Hierarchy.default)
        users += entry_in_default.taxon_concept.curators
      end
    end
    @curators = users
    return users
  end
  
  def all_ancestor_entry_ids
    all_ancestor_entry_ids = []
    entries = HierarchyEntry.find_all_by_taxon_concept_id(self.id, :select => 'id, parent_id')
    all_ancestor_entry_ids += entries.collect{|he| he.id }
    
    # getting all the parents of entries in this concept, and the other entries in their concepts
    while parents = HierarchyEntry.find_all_by_id(entries.collect{|he| he.parent_id}.uniq, :joins => 'JOIN hierarchy_entries he_concept USING (taxon_concept_id)', :select => 'hierarchy_entries.id, hierarchy_entries.parent_id, he_concept.id related_he_id', :conditions => "hierarchy_entries.id != 0")
      break if parents.empty?
      all_ancestor_entry_ids += parents.collect{|he| he.id }
      all_ancestor_entry_ids += parents.collect{|he| he['related_he_id']}
      entries = parents.dup
      break if entries.collect{|he| he.parent_id} == [0]
    end
    return all_ancestor_entry_ids.uniq
  end
  

  # Return the curators who actually get credit for what they have done (for example, a new curator who hasn't done
  # anything yet doesn't get a citation).  Also, curators should only get credit on the pages they actually edited,
  # not all of it's children.  (For example.)
  def acting_curators
    # Single-database query using a thousandfold more efficient algorithm than doing things via cross-database join:
    User.all(:joins => :last_curated_dates, :conditions => "last_curated_dates.last_curated >= '#{2.years.ago.to_s(:db)}' AND last_curated_dates.taxon_concept_id = #{self.id}").uniq
  end
  
  # if curator is no longer able to curate the page, citation should still show up, so we grab all users wich had have curator activity in 2 last years on this page
  def curator_has_citation
    last_curated_dates = LastCuratedDate.find(:all, :conditions => ["taxon_concept_id = ? AND last_curated > ?", self.id, 2.years.ago.to_s(:db)])
    user_ids = last_curated_dates.map { |a| a[:user_id] }.uniq
    User.find(user_ids)
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
    return content_by_category(TocItem.overview)[:data_objects]
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

  # Try not to call this unless you know what you're doing.  :) See scientific_name and common_name instead.
  #
  # That said, this method allows you to get other variations on a name.  See HierarchyEntry#name, to which this is
  # really delegated, unless there is no entry in the default Hierarchy, in which case, see
  # #alternate_classification_name.
  def name(detail_level = :middle, language = Language.english, context = nil)
    col_he = hierarchy_entries.detect {|he| he.hierarchy_id == Hierarchy.default.id }
    return col_he.nil? ? alternate_classification_name(detail_level, language, context).firstcap : col_he.name(detail_level, language, context).firstcap
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
    hierarchy_entries.detect {|he| he.species_or_below? }
  end

  def has_outlinks?
    return true unless outlinks.empty?
  end

  def outlinks
    all_outlinks = []
    used_hierarchies = []
    entries_for_this_concept = HierarchyEntry.find_all_by_taxon_concept_id(id, :include => :hierarchy)
    entries_for_this_concept.each do |he|
      next if used_hierarchies.include?(he.hierarchy)
      next if he.published != 1 && he.visibility_id != Visibility.visible.id
      if !he.source_url.blank?
        all_outlinks << {:hierarchy_entry => he, :hierarchy => he.hierarchy, :outlink_url => he.source_url }
        used_hierarchies << he.hierarchy
      elsif !he.hierarchy.outlink_uri.blank?
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
    hierarchy_entries.each do |entry|
      return entry.identifier if entry.has_gbif_identifier?
    end
    return empty_map_id
  end

  def hierarchy_entries_with_parents
    HierarchyEntry.with_parents self
  end
  alias hierarchy_entries_with_ancestors hierarchy_entries_with_parents

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
    return videos.length > $MAX_IMAGES_PER_PAGE.to_i # This is expensive.  I hope you called #videos first!
  end

  def videos(options = {})
    usr = current_user
    if options[:unvetted]
      usr = current_user.clone
      usr.vetted = false
    end
    videos = DataObject.for_taxon(self, :video, :agent => @current_agent, :user => usr)
    @length_of_videos = videos.length # cached, so we don't have to query this again.
    return videos
  end 

  # Singleton method to fetch the Hierarchy Entry, used for taxonomic relationships
  def entry(hierarchy = nil, strict_lookup = false)
    hierarchy ||= Hierarchy.default
    raise "Error finding default hierarchy" if hierarchy.nil? # EOLINFRASTRUCTURE-848
    raise "Cannot find a HierarchyEntry with anything but a Hierarchy" unless hierarchy.is_a? Hierarchy

    # get all hierarchy entries
    @all_entries ||= HierarchyEntry.find_by_sql("SELECT he.*, v.view_order vetted_view_order FROM hierarchy_entries he JOIN vetted v ON (he.vetted_id=v.id) WHERE he.taxon_concept_id=#{id}")
    # ..and order them by published DESC, vetted view_order ASC, id ASC - earliest entry first
    @all_entries.sort! do |a,b|
      if a.published == b.published
        if a.vetted_view_order == b.vetted_view_order
          a.id <=> b.id # ID ascending
        else
          a.vetted_view_order <=> b.vetted_view_order # vetted view_order ascending
        end
      else
        b.published <=> a.published # published descending
      end
    end

    # we want ONLY the entry in this hierarchy
    if strict_lookup
      return @all_entries.detect{ |he| he.hierarchy_id == hierarchy.id } || nil
    end

    return @all_entries.detect{ |he| he.hierarchy_id == hierarchy.id } ||
      @all_entries[0] ||
      nil
  end

  def self.entries_for_concepts(taxon_concept_ids, hierarchy = nil, strict_lookup = false)
    hierarchy ||= Hierarchy.default
    raise "Error finding default hierarchy" if hierarchy.nil? # EOLINFRASTRUCTURE-848
    raise "Cannot find a HierarchyEntry with anything but a Hierarchy" unless hierarchy.is_a? Hierarchy
    raise "Must get an array of taxon_concept_ids" unless taxon_concept_ids.is_a? Array

    # get all hierarchy entries
    all_entries = HierarchyEntry.find_by_sql("SELECT he.*, v.view_order vetted_view_order FROM hierarchy_entries he JOIN vetted v ON (he.vetted_id=v.id) WHERE he.taxon_concept_id IN (#{taxon_concept_ids.join(',')})")
    # ..and order them by published DESC, vetted view_order ASC, id ASC - earliest entry first
    all_entries.sort! do |a,b|
      if a.taxon_concept_id == b.taxon_concept_id
        if a.published == b.published
          if a.vetted_view_order == b.vetted_view_order
            a.id <=> b.id # ID ascending
          else
            a.vetted_view_order <=> b.vetted_view_order # vetted view_order ascending
          end
        else
          b.published <=> a.published # published descending
        end
      else
        a.taxon_concept_id <=> b.taxon_concept_id # taxon_concept_id ascending
      end
    end

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
  def children_hash(detail_level = :middle, language = Language.english, hierarchy = nil, secondary_hierarchy = nil)
    h_entry = entry(hierarchy)
    return {} unless h_entry
    return h_entry.children_hash(detail_level, language, hierarchy, secondary_hierarchy)
  end
  def ancestors_hash(detail_level = :middle, language = Language.english, cross_reference_hierarchy = nil, secondary_hierarchy = nil)
    h_entry = entry(cross_reference_hierarchy)
    return {} unless h_entry
    return h_entry.ancestors_hash(detail_level, language, cross_reference_hierarchy, secondary_hierarchy)
  end  

  # general versions of the above methods for any hierarchy
  def find_ancestor_in_hierarchy(hierarchy)
    hierarchy_entries.each do |entry|
      this_entry_in = entry.find_ancestor_in_hierarchy(hierarchy)
      return this_entry_in if this_entry_in
    end
    return nil
  end

  def maps_to_hierarchy?(hierarchy)
    return !find_ancestor_in_hierarchy(hierarchy).nil?
  end

  # TODO - this method should have a ? at the end of its name
  def in_hierarchy?(search_hierarchy = nil)
    return false unless search_hierarchy
    entries = hierarchy_entries.detect {|he| he.hierarchy_id == search_hierarchy.id }
    return entries.nil? ? false : true
  end

  def self.find_entry_in_hierarchy(taxon_concept_id, hierarchy_id)
    return HierarchyEntry.find_by_sql("SELECT he.* FROM hierarchy_entries he WHERE taxon_concept_id=#{taxon_concept_id} AND hierarchy_id=#{hierarchy_id} LIMIT 1").first
  end

  # We do have some content that is specific to COL, so we need a method that will ALWAYS reference it:
  def col_entry
    return @col_entry unless @col_entry.nil?
    hierarchy_id = Hierarchy.default.id
    return @col_entry = hierarchy_entries.detect{ |he| he.hierarchy_id == hierarchy_id }
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

  def has_map
    available_media if @has_media.nil?
    @has_media[:map]
  end

  def available_media
    images = video = map = false
    # TODO - JRice believes these rescues are bad.  They are--I assume--in here because sometimes there is no
    # hierarchies_content.  However, IF there is one AND we get some other errors, then A) we're not handling them,
    # and B) The value switches to false when it may have been true from a previous hierarchies_content.
    hierarchy_entries.each do |entry|
      images = true if entry.hierarchies_content.image != 0 || entry.hierarchies_content.child_image != 0 rescue images
      video = true if entry.hierarchies_content.flash != 0 || entry.hierarchies_content.youtube != 0 rescue video
      map = true if entry.hierarchies_content.map != 0 rescue map
    end

    map = false if map and gbif_map_id == empty_map_id # The "if map" avoids unecessary db hits; keep it.

    if !video then    
      # to accomodate data_type => http://purl.org/dc/dcmitype/MovingImage = Video
      with_video = DataObject.find_by_sql("Select data_objects.data_type_id
      From data_objects_taxon_concepts Inner Join data_objects ON data_objects_taxon_concepts.data_object_id = data_objects.id
      Where data_objects_taxon_concepts.taxon_concept_id = #{self.id} and data_objects.data_type_id IN (#{DataType.video.id}, #{DataType.flash.id}, #{DataType.youtube.id})")    
      video = true if with_video.length > 0
    end

    @has_media = {:images => images, :video  => video, :map    => map }
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
    # Notice that we use find_by, not find_all_by.  We require that only one match (or no match) is found.
    # TODO - hack on [].flatten to handle two cases, which we currently have between prod and dev.  Fix this in the
    # next iteration (any after 2.9):
    iucn_objects = DataObject.find_by_sql("
        SELECT do.*
          FROM hierarchy_entries he
            JOIN data_objects_hierarchy_entries dohe ON (he.id = dohe.hierarchy_entry_id)
            JOIN data_objects do ON (dohe.data_object_id = do.id)
        WHERE he.taxon_concept_id = #{self.id}
          AND he.hierarchy_id = #{Resource.iucn.hierarchy_id}
          AND he.published = 1
          AND do.published = 1")

    iucn_objects.sort! do |a,b|
      b.id <=> a.id
    end
    my_iucn = iucn_objects[0] || nil

    temp_iucn = my_iucn.nil? ? DataObject.new(:source_url => 'http://www.iucnredlist.org/', :description => 'NOT EVALUATED') : my_iucn
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
    return '' unless entry(hierarchy)
    return entry(hierarchy).classification_attribution
  end

  # This may throw an ActiveRecord::RecordNotFound exception if the TocItem's category_id doesn't exist.
  def content_by_category(category_id, options = {})
    toc_item = TocItem.find(category_id) # Note: this "just works" even if category_id *is* a TocItem.
    ccb = CategoryContentBuilder.new
    if ccb.can_handle?(toc_item)
      ccb.content_for(toc_item, :vetted => current_user.vetted, :taxon_concept_id => id)
    else
      get_default_content(toc_item)
    end
  end

  def images(options = {})

    # TODO - dump this.  Forces a check to see if the current user is valid:
    unless self.current_user.attributes.keys.include?('filter_content_by_hierarchy')
      self.current_user = User.create_new
    end

    # set hierarchy to filter images by
    if self.current_user.filter_content_by_hierarchy && self.current_user.default_hierarchy_valid?
      filter_hierarchy = Hierarchy.find(self.current_user.default_hierarchy_id)
    else
      filter_hierarchy = nil
    end
    perform_filter = !filter_hierarchy.nil?

    image_page = (options[:image_page] ||= 1).to_i
    images ||= DataObject.for_taxon(self, :image, :user => self.current_user, :agent => @current_agent, :filter_by_hierarchy => perform_filter, :hierarchy => filter_hierarchy, :image_page => image_page)
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
    hierarchy ||= Hierarchy.default
    title = quick_scientific_name(:italicized, hierarchy)
    title = title.blank? ? name(:scientific) : title
    @title = title.firstcap
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

  alias :ar_to_xml :to_xml
  # Be careful calling a block here.  We have our own builder, and you will be overriding that if you use a block.
  def to_xml(options = {})
    options[:root]    ||= 'taxon-page'
    options[:only]    ||= [:id]
    options[:methods] ||= [:canonical_form, :iucn_conservation_status, :scientific_name]
    default_block = nil
    if options[:full]
      options[:methods] ||= [:canonical_form, :iucn_conservation_status, :scientific_name]
      default_block = lambda do |xml|

        # Using tag! here because hyphens are not legal ruby identifiers.
        xml.tag!('common-names') do
          all_common_names.each do |cn|
            xml.item { xml.language_label cn.language_label ; xml.string cn.string }
          end
        end

        xml.overview { overview.to_xml(:builder => xml, :skip_instruct => true) 
          overview.map{|x| x.visible_references.to_xml(:builder => xml, :skip_instruct => true) }
          }

        # Using tag! here because hyphens are not legal ruby identifiers.
        xml.tag!('table-of-contents') do
          toc.each do |ti|
            xml.item { xml.id ti.category_id ; xml.label ti.label }
          end
        end

        # Careful!  We're doing TaxonConcepts, here, so we don't want recursion.
        xml.ancestors { ancestors.each { |a| a.to_xml(:builder => xml, :skip_instruct => true) } }
        # Careful!  We're doing TaxonConcepts, here, too, so we don't want recursion.
        xml.children { children.each { |a| a.to_xml(:builder => xml, :skip_instruct => true) } }
        xml.curators { curators.each {|c| c.to_xml(:builder => xml, :skip_instruct => true)} }

        # There are potentially lots and lots of these, so let's just count them and let the user grab what they want:
        xml.comments { xml.count comments.length.to_s }
        xml.images   { xml.count images.length.to_s }
        xml.videos   { xml.count videos.length.to_s }

      end
    end
    if block_given?
      return ar_to_xml(options) { |xml| yield xml }
    else 
      if default_block.nil?
        return ar_to_xml(options)
      else
        return ar_to_xml(options) { |xml| default_block.call(xml) }
      end
    end
  end



  def self.synonyms(taxon_concept_id)
    syn_hash = SpeciesSchemaModel.connection.execute("
      SELECT n_he.string preferred_name, n_s.string synonym, sr.label relationship, h.label hierarchy_label
      FROM hierarchy_entries he
      JOIN synonyms s ON (he.id=s.hierarchy_entry_id)
      JOIN hierarchies h ON (he.hierarchy_id=h.id)
      JOIN names n_he ON (he.name_id=n_he.id)
      JOIN names n_s ON (s.name_id=n_s.id)
      LEFT JOIN synonym_relations sr ON (s.synonym_relation_id=sr.id)
      WHERE he.taxon_concept_id=#{taxon_concept_id}
      AND h.browsable=1
      AND s.synonym_relation_id NOT IN (#{SynonymRelation.common_name_ids.join(',')})
    ").all_hashes.uniq

    syn_hash.sort! do |a,b|
      if a['hierarchy_label'] == b['hierarchy_label']
        a['synonym'] <=> b['synonym']
      else
        a['hierarchy_label'] <=> b['hierarchy_label']
      end
    end

    # grouped = {}
    # for syn in syn_hash
    #   key = syn['synonym'].downcase
    #   grouped[key] ||= {'name_string' => parent['synonym'], 'sources' => []}
    #   grouped[key]['sources'] << parent
    # end
    # grouped.each do |key, hash|
    #   hash['sources'].sort! {|a,b| a['hierarchy_label'] <=> b['hierarchy_label']}
    # end
    # grouped = grouped.sort {|a,b| a[0] <=> b[0]}

    # group synonyms by hierarchy
    grouped = []
    working_hash = {}
    last_hierarchy = nil
    for syn in syn_hash
      if syn['hierarchy_label'] != last_hierarchy
        grouped << working_hash unless working_hash.empty?
        working_hash = {'hierarchy_label' => syn['hierarchy_label'],
                        'preferred_name'  => syn['preferred_name'],
                        'synonyms'        => []}
      end
      syn['relationship'] = 'synonym' if syn['relationship'].nil?
      ar = {'name' => syn['synonym'], 'relationship' => syn['relationship']}
      working_hash['synonyms'] << ar
      last_hierarchy = syn['hierarchy_label']
    end
    grouped << working_hash unless working_hash.empty?

    return grouped
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

  def self.entry_stats(taxon_concept_id)
    SpeciesSchemaModel.connection.execute("SELECT he.id, h.label hierarchy_label, hes.*, h.id hierarchy_id
      FROM hierarchy_entries he
      JOIN hierarchies h ON (he.hierarchy_id=h.id)
      JOIN hierarchy_entry_stats hes ON (he.id=hes.hierarchy_entry_id)
      WHERE he.taxon_concept_id=#{taxon_concept_id}
      AND h.browsable=1
      AND he.published=1
      AND he.visibility_id=#{Visibility.visible.id}
      GROUP BY h.id
      ORDER BY h.label").all_hashes
  end

  # for API
  def details_hash(options = {})
    options[:return_images_limit] ||= 3
    options[:return_videos_limit] ||= 1
    options[:return_text_limit] ||= 1
    if options[:subjects]
      options[:text_subjects] = options[:subjects].split("|")
    else
      options[:text_subjects] = ['TaxonBiology', 'GeneralDescription', 'Description']
    end
    if options[:licenses]
      options[:licenses] = options[:licenses].split("|").map do |l|
        if l == 'pd'
          'public domain'
        elsif l == 'na'
          'not applicable'
        else
          l
        end
      end
    else
      # making this an array to keep it consistent
      options[:licenses] = ['all']
    end
    

    if options[:data_object_hash]
      # needs to be an array
      data_object_hash = [ options[:data_object_hash] ]
    else
      image_ids = top_image_ids(options)
      non_image_ids = top_non_image_ids(options)
      data_object_hash = DataObject.details_for_objects(image_ids + non_image_ids, :skip_metadata => !options[:details])
    end

    common = options[:common_names].blank? ? [] : preferred_common_names_hash
    curated_hierarchy_entries = hierarchy_entries.delete_if{|he| he.hierarchy.browsable!=1 || he.published==0 || he.visibility_id!=Visibility.visible.id }

    details_hash = {  'data_objects'              => data_object_hash,
                      'id'                        => self.id,
                      'scientific_name'           => quick_scientific_name,
                      'common_names'              => common,
                      'curated_hierarchy_entries' => curated_hierarchy_entries}
  end

  def top_image_ids(options = {})
    return [] if options[:return_images_limit] == 0
    # a user with default options - to show unvetted images for example
    user = User.create_new
    top_images_sql = DataObject.build_top_images_query(self, :user => user)
    object_hash = SpeciesSchemaModel.connection.execute(top_images_sql).all_hashes
    object_hash = object_hash.uniq

    object_hash = ModelQueryHelper.sort_object_hash_by_display_order(object_hash)

    if options[:vetted].to_i == 1
      object_hash.delete_if {|obj| obj['vetted_id'].to_i != Vetted.trusted.id}
    elsif options[:vetted].to_i == 2
      object_hash.delete_if {|obj| obj['vetted_id'].to_i == Vetted.untrusted.id}
    end
    
    # remove licenses not asked for
    if !options[:licenses].include?('all')
      object_hash.each_with_index do |obj, index|
        valid_license = false
        options[:licenses].each do |l|
          if !obj['license_title'].nil? && obj['license_title'].match(/^#{l}( |$)/i)
            valid_license = true
          end
        end
        object_hash[index] = nil unless valid_license == true
      end
      object_hash.compact!
    end
    
    object_hash = object_hash[0...options[:return_images_limit]] if object_hash.length > options[:return_images_limit]
    object_hash.collect {|e| e['id']}
  end

  def top_non_image_ids(options = {})
    return [] if options[:return_images_limit] == 0 && options[:return_videos_limit] == 0 && options[:return_text_limit] == 0
    vetted_clause = ""
    if options[:vetted].to_i == 1
      vetted_clause = "AND do.vetted_id=#{Vetted.trusted.id}"
    elsif options[:vetted].to_i == 2
      vetted_clause = "AND (do.vetted_id=#{Vetted.trusted.id} || do.vetted_id=#{Vetted.unknown.id})"
    end
    
    object_hash = SpeciesSchemaModel.connection.execute("
      SELECT do.id, do.guid, do.data_type_id, do.data_rating, v.view_order vetted_view_order, toc.view_order toc_view_order, 
      ii.label info_item_label, l.title license_title
        FROM data_objects_taxon_concepts dotc
        JOIN data_objects do ON (dotc.data_object_id = do.id)
        LEFT JOIN vetted v ON (do.vetted_id=v.id)
        LEFT JOIN licenses l ON (do.license_id=l.id)
        LEFT JOIN (
           info_items ii
           JOIN table_of_contents toc ON (ii.toc_id=toc.id)
           JOIN data_objects_table_of_contents dotoc ON (toc.id=dotoc.toc_id)
          ) ON (do.id=dotoc.data_object_id)
        WHERE dotc.taxon_concept_id = #{self.id}
        AND do.published = 1
        AND do.visibility_id = #{Visibility.visible.id}
        AND data_type_id IN (#{DataType.sound.id}, #{DataType.text.id}, #{DataType.video.id}, #{DataType.iucn.id}, #{DataType.flash.id}, #{DataType.youtube.id})
        #{vetted_clause}
    ").all_hashes.uniq
    
    object_hash.group_hashes_by!('guid')
    object_hash = ModelQueryHelper.sort_object_hash_by_display_order(object_hash)
    
    # set flash and youtube types to video
    text_id = DataType.text.id.to_s
    image_id = DataType.image.id.to_s
    video_id = DataType.video.id.to_s
    flash_id = DataType.flash.id.to_s
    youtube_id = DataType.youtube.id.to_s
    iucn_id = DataType.iucn.id
    object_hash.each_with_index do |r, index|
      if r['data_type_id'] == flash_id || r['data_type_id'] == youtube_id
        r['data_type_id'] = video_id
      end
      if r['data_type_id'].to_i == iucn_id
        r['data_type_id'] = text_id
      end
    end
    
    # create an alias Uses for Use
    if options[:text_subjects].include?('Use')
      options[:text_subjects] << 'Uses'
    end
    # remove text subjects not asked for
    if !options[:text_subjects].include?('all')
      object_hash.delete_if {|obj| obj['data_type_id'] == text_id && !options[:text_subjects].include?(obj['info_item_label'])}
    end
    
    # remove licenses not asked for
    if !options[:licenses].include?('all')
      object_hash.each_with_index do |obj, index|
        valid_license = false
        options[:licenses].each do |l|
          if !obj['license_title'].nil? && obj['license_title'].match(/^#{l}( |$)/i)
            valid_license = true
          end
        end
        object_hash[index] = nil unless valid_license == true
      end
      object_hash.compact!
    end
    
    # remove items over the limit
    types_count = {}
    truncated_object_hash = []
    object_hash.each do |r|
      types_count[r['data_type_id']] ||= 0
      types_count[r['data_type_id']] += 1
      
      if r['data_type_id'] == text_id
        truncated_object_hash << r if types_count[r['data_type_id']] <= options[:return_text_limit]
      elsif r['data_type_id'] == image_id
        truncated_object_hash << r if types_count[r['data_type_id']] <= options[:return_images_limit]
      elsif r['data_type_id'] == video_id
        truncated_object_hash << r if types_count[r['data_type_id']] <= options[:return_videos_limit]
      end
    end

    truncated_object_hash.collect {|e| e['id']}
  end

  def preferred_common_names_hash
    names_array = []
    language_codes_used = []
    common_names = EOL::CommonNameDisplay.find_by_taxon_concept_id(self.id)
    for name in common_names
      next if name.preferred != true
      next if name.iso_639_1.blank?
      next if language_codes_used.include?(name.iso_639_1)
      name_hash = {'name_string' => name.name_string, 'iso_639_1' => name.iso_639_1}
      names_array << name_hash unless names_array.include?(name_hash)
      language_codes_used << name.iso_639_1
    end
    return names_array
  end







  def all_common_names
    Name.find_by_sql(['SELECT names.string, l.iso_639_1 language_label, l.label, l.name
                         FROM taxon_concept_names tcn JOIN names ON (tcn.name_id = names.id)
                           LEFT JOIN languages l ON (tcn.language_id = l.id)
                         WHERE tcn.taxon_concept_id = ? AND vern = 1
                         ORDER BY language_label, string', id])
  end

  # Unlike all_common_names, this method doesn't return language information.  In theory, they are all "scientific", anyway.
  def all_scientific_names
    Name.find_by_sql(['SELECT names.string
                         FROM taxon_concept_names tcn JOIN names ON (tcn.name_id = names.id)
                         WHERE tcn.taxon_concept_id = ? AND vern = 0', id])
  end

  def self.related_names_for?(taxon_concept_id)
    has_parents = TaxonConcept.count_by_sql("SELECT 1
                                      FROM hierarchy_entries he
                                      JOIN hierarchies h ON (he.hierarchy_id=h.id)
                                      WHERE he.taxon_concept_id=#{taxon_concept_id}
                                      AND he.published=1
                                      AND parent_id!=0
                                      AND h.browsable=1
                                      LIMIT 1") > 0
    return true if has_parents

    return TaxonConcept.count_by_sql("SELECT 1
                                      FROM hierarchy_entries he
                                      JOIN hierarchy_entries he_children ON (he.id=he_children.parent_id)
                                      JOIN hierarchies h ON (he_children.hierarchy_id=h.id)
                                      WHERE he.taxon_concept_id=#{taxon_concept_id}
                                      AND h.browsable=1
                                      AND he_children.published=1
                                      LIMIT 1") > 0
  end

  def self.synonyms_for?(taxon_concept_id)
    return TaxonConcept.count_by_sql("SELECT 1
                                      FROM hierarchy_entries he
                                      JOIN hierarchies h ON (he.hierarchy_id=h.id)
                                      JOIN synonyms s ON (he.id=s.hierarchy_entry_id)
                                      WHERE he.taxon_concept_id=#{taxon_concept_id}
                                      AND he.published=1
                                      AND h.browsable=1
                                      AND s.synonym_relation_id NOT IN (#{SynonymRelation.common_name_ids.join(',')})
                                      LIMIT 1") > 0
  end

  def self.common_names_for?(taxon_concept_id)
    return TaxonConcept.count_by_sql(['SELECT 1 FROM taxon_concept_names tcn 
                                        WHERE taxon_concept_id = ? 
                                          AND vern = 1 
                                        LIMIT 1',taxon_concept_id]) > 0
  end

  def add_common_name_synonym(name_string, options = {})
    agent     = options[:agent]
    preferred = !!options[:preferred]
    language  = options[:language] || Language.unknown
    vetted    = options[:vetted] || Vetted.unknown
    relation  = SynonymRelation.find_by_label("common name") # TODO - i18n
    name_obj  = Name.create_common_name(name_string)
    Synonym.generate_from_name(name_obj, :agent => agent, :preferred => preferred, :language => language,
                               :entry => entry, :relation => relation, :vetted => vetted)
  end

  def delete_common_name(taxon_concept_name)
    language_id = taxon_concept_name.language.id
    syn_id = taxon_concept_name.synonym.id
    Synonym.find(syn_id).destroy
  end

  # only unsed in tests--this would be really slow with real data
  def data_objects
    DataObject.find_by_sql("
      SELECT do.*
      FROM hierarchy_entries he
      JOIN data_objects_hierarchy_entries dohe ON (he.id=dohe.hierarchy_entry_id)
      JOIN data_objects do ON (dohe.data_object_id=do.id)
      WHERE he.taxon_concept_id=#{self.id}")
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

  def alternate_classification_name(detail_level = :middle, language = Language.english, context = nil)
    self.entry.name(detail_level, language, context).firstcap rescue '?-?'
  end

  def empty_map_id
    return 1
  end

  def get_default_content(category_id)
    result = {
      :content_type  => 'text',
      :category_name => TocItem.find(category_id).label,
      :data_objects  => DataObject.for_taxon(self, :text, :toc_id => category_id, :agent => @current_agent, :user => current_user)
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
        (genus, species) = entry.name(:canonical).split()
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

