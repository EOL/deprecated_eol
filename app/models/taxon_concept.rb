# Represents a group of HierearchyEntry instances that we consider "the same".  This amounts to a vague idea
# of a taxon, which we serve as a single page.
#
# We get different interpretations of taxa from our partners (ContentPartner), often differing slightly 
# and referring to basically the same thing, so TaxonConcept was created as a means to reconcile the 
# variant definitions of what are essentially the same Taxon. We currently store basic Taxon we receive
# from data imports in the +taxa+ table and we also store taxonomic hierarchies (HierarchyEntry) in the 
# +hierarchy_entries+ table. Currently TaxonConcept are groups of one or many HierarchyEntry. We will 
# eventually create hierarchy_entries for each entry in the taxa table (Taxon).
#
# It is worth mentioning that the "eol.org/pages/nnnn" route is a misnomer.  Those IDs are, for the
# time-being, pointing to TaxonConcept, not pages.
#
# See the comments at the top of the Taxon for more information on this.
# I include there a basic biological definition of what a Taxon is.
require 'eol/solr_search'

class TaxonConcept < SpeciesSchemaModel
  extend EOL::Solr::Search

  #TODO belongs_to :taxon_concept_content
  belongs_to :vetted

  has_many :hierarchy_entries
  has_many :top_concept_images
  has_many :top_unpublished_concept_images
  has_many :last_curated_dates
  has_many :taxon_concept_names
  has_many :comments, :as => :parent, :attributes => true
  has_many :names, :through => :taxon_concept_names
  has_many :ranks, :through => :hierarchy_entries
  # The following are not (yet) possible, because tcn has a three-part Primary key.
  # has_many :taxa, :through => :names, :source => :taxon_concept_names
  # has_many :mappings, :through => :names, :source => :taxon_concept_names
  has_many :google_analytics_partner_taxa
  

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

  # Given a Languge (object) and name_id, this sets all other names within that language to non-preferred, and the
  # provided name_id to preferred for this TaxonConcept and Language.
  def set_preferred_name(language, name_id)
    old_preferred_names = []
    new_preferred_name = nil 
    taxon_concept_names.each do |tcn|
      old_preferred_names << tcn if tcn.language_id == language.id and tcn.preferred == 1
      new_preferred_name = tcn if tcn.language_id == language.id and tcn.name_id == name_id
    end
    if new_preferred_name
      unless old_preferred_names.empty?
        old_preferred_names.each do |old_preferred_name|
          old_preferred_name.set_preferred(0)
        end
      end
      new_preferred_name.set_preferred(1)
    else
      raise "Couldn't find a TaxonConceptName with a name_id of #{name_id}"
    end
    return true
  end

  # Curators are those users who have special permission to "vet" data objects associated with a TC, and thus get
  # extra credit on their associated TC pages. This method returns an Array of those users.
  def curators
    users = User.find_by_sql(default_hierarchy_curators_clause)
    unless in_hierarchy(Hierarchy.default)
      users += find_ancestor_in_hierarchy(Hierarchy.default).taxon_concept.curators if maps_to_hierarchy(Hierarchy.default)
    end
    return users
  end
  def ssm_db
    SpeciesSchemaModel.connection.current_database
  end
  def default_hierarchy_curators_clause
    "SELECT DISTINCT users.*
     FROM  #{ssm_db}.hierarchy_entries children
       JOIN  #{ssm_db}.hierarchy_entries ancestor
         ON (children.lft BETWEEN ancestor.lft AND ancestor.rgt AND children.hierarchy_id=ancestor.hierarchy_id)
       JOIN  #{ssm_db}.hierarchy_entries ancestor_concepts
         ON (ancestor.taxon_concept_id=ancestor_concepts.taxon_concept_id)
       JOIN users ON (ancestor_concepts.id=users.curator_hierarchy_entry_id)
     WHERE curator_approved IS TRUE
       AND children.taxon_concept_id = #{self.id}"
  end

  # Return the curators who actually get credit for what they have done (for example, a new curator who hasn't done
  # anything yet doesn't get a citation).  Also, curators should only get credit on the pages they actually edited,
  # not all of it's children.  (For example.)
  def acting_curators
    # Cross-database join using a thousandfold more efficient algorithm than doing things separately:
    ssm_db = SpeciesSchemaModel.connection.current_database
    User.find_by_sql("
      SELECT DISTINCT users.*
      FROM users
        JOIN last_curated_dates lcd ON (users.id = lcd.user_id AND lcd.last_curated >= '#{2.years.ago.to_s(:db)}')
        JOIN #{ssm_db}.hierarchy_entries ancestor ON (users.curator_hierarchy_entry_id = ancestor.id)
        JOIN #{ssm_db}.hierarchy_entries children ON (ancestor.id = children.id
                                                      OR (ancestor.hierarchy_id = children.hierarchy_id
                                                          AND ancestor.lft < children.lft
                                                          AND ancestor.rgt > children.rgt))
      WHERE curator_approved IS TRUE
        AND lcd.taxon_concept_id = #{self.id}
        AND children.taxon_concept_id = #{self.id}  -- TaxonConcept#approved_curators
    ")
  end
  alias :active_curators :acting_curators

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
    curators.include?(user)
  end

  # Return a list of data objects associated with this TC's Overview toc (returns nil if it doesn't have one)
  def overview
    return content_by_category(TocItem.overview)[:data_objects]
  end

  # The scientific name for a TC will be italicized if it is a species (or below) and will include attribution and varieties, etc:
  def scientific_name(hierarchy = nil)
    hierarchy ||= Hierarchy.default
    quick_scientific_name(species_or_below? ? :italicized : :normal, hierarchy)
  end

  # pull list of categories for given taxa id
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
    Rails.cache.fetch('taxon_concepts/exemplars') do
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

  # Because nested has_many_through won't work with CPKs:
  def mappings
    Rails.cache.fetch("taxon_concepts/#{self.id}/mappings") do
      Mapping.for_taxon_concept_id(self.id).sort_by {|m| m.id }
    end
  end

  # I chose not to make this singleton since it should really only ever get called once:
  def ping_host_urls
    host_urls = []
    mappings.each do |mapping|
      host_urls << mapping.ping_host_url unless mapping.collection.nil? or mapping.ping_host? == false 
    end
    return host_urls
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

  def videos
    videos = DataObject.for_taxon(self, :video, :agent => @current_agent, :user => current_user)
    @length_of_videos = videos.length # cached, so we don't have to query this again.
    return videos
  end 

  # Singleton method to fetch the Hierarchy Entry, used for taxonomic relationships
  def entry(hierarchy = nil)
    hierarchy ||= Hierarchy.default
    raise "Error finding default hierarchy" if hierarchy.nil? # EOLINFRASTRUCTURE-848
    raise "Cannot find a HierarchyEntry with anything but a Hierarchy" unless hierarchy.is_a? Hierarchy
    return hierarchy_entries.detect{ |he| he.hierarchy_id == hierarchy.id } ||
      hierarchy_entries.compact[0] ||
      nil
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
    return nil if entry(hierarchy).nil?
    return entry(hierarchy).kingdom(hierarchy)
  end
  def children_hash(detail_level = :middle, language = Language.english, hierarchy = nil, secondary_hierarchy = nil)
    return {} unless entry(hierarchy)
    return entry(hierarchy).children_hash(detail_level, language, hierarchy, secondary_hierarchy)
  end
  def ancestors_hash(detail_level = :middle, language = Language.english, cross_reference_hierarchy = nil, secondary_hierarchy = nil)
    return {} unless entry(cross_reference_hierarchy)
    return entry(cross_reference_hierarchy).ancestors_hash(detail_level, language, cross_reference_hierarchy, secondary_hierarchy)
  end  
  
  # general versions of the above methods for any hierarchy
  def find_ancestor_in_hierarchy(hierarchy)
    hierarchy_entries.each do |entry|
      this_entry_in = entry.find_ancestor_in_hierarchy(hierarchy)
      return this_entry_in if this_entry_in
    end
    return nil
  end
  
  def maps_to_hierarchy(hierarchy)
    return !find_ancestor_in_hierarchy(hierarchy).nil?
  end
  
  # TODO - this method should have a ? at the end of its name
  def in_hierarchy(search_hierarchy = nil)
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
  
  def quick_scientific_name(type = :normal, hierarchy = nil)
    hierarchy ||= Hierarchy.default
    
    scientific_name_results = []
    
    search_type = case type
      when :italicized  then {:name_field => 'n.italicized', :also_join => ''}
      when :canonical   then {:name_field => 'cf.string',    :also_join => 'JOIN canonical_forms cf ON (n.canonical_form_id = cf.id)'}
      else                   {:name_field => 'n.string',     :also_join => ''}
    end

    scientific_name_results = SpeciesSchemaModel.connection.execute(
      "SELECT #{search_type[:name_field]} name, he.hierarchy_id source_hierarchy_id
       FROM taxon_concept_names tcn JOIN names n ON (tcn.name_id = n.id) #{search_type[:also_join]}
         LEFT JOIN hierarchy_entries he ON (tcn.source_hierarchy_entry_id = he.id)
       WHERE tcn.taxon_concept_id=#{id} AND vern=0 AND preferred=1").all_hashes

    final_name = ''
    
    # This loop is to check to make sure the default hierarchy's preferred name takes precedence over other hierarchy's preferred names 
    scientific_name_results.each do |result|
      if final_name == '' || result['source_hierarchy_id'].to_i == hierarchy.id
        final_name = result['name'].firstcap
      end
    end
    
    return final_name

  end

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
      concept = TaxonConcept.find_without_supercedure(concept.supercedure_id, *args[1..-1])
      attempts += 1
    end
    concept.superceded_the_requested_id # Sets a flag that we can check later.
    return concept
  end
  class << self; alias_method_chain :find, :supercedure ; end

  def self.quick_search(search_string, options = {})
    options[:user] ||= User.create_new
    
    search_terms = search_string.downcase.gsub(/\s+/, ' ').strip.split(/[ -&:\\'?;]+| and /)
    
    sci_concepts          = []
    com_concepts          = []
    modified_search_terms = []
    errors = nil

    search_terms.uniq.each do |orig_term|
      term = orig_term.gsub(/\*/, 'EOL_WILDCARD').gsub(/[\W\-]/, '').gsub('EOL_WILDCARD', '%')
      if term.gsub('%', '').length < 3
        errors ||= []
        errors << "All search terms must contain at least three characters. '#{orig_term}' is too short."
      end
      
      search_type = term.match(/%/) ? 'LIKE' : '='
      
      modified_search_terms << "nn.name_part #{search_type} '#{term}'"
    end
    
    if modified_search_terms.length == 0 
      return {:common     => com_concepts,
              :scientific => sci_concepts,
              :errors     => errors}
    end
    
    name_ids = SpeciesSchemaModel.connection.select_values(%Q{
      SELECT name_id, count(*)
      FROM normalized_names nn STRAIGHT_JOIN normalized_links nl ON (nn.id = nl.normalized_name_id)
      WHERE (#{modified_search_terms.join(' OR ')}) AND nl.normalized_qualifier_id=1
      GROUP BY name_id HAVING count(*)>=#{modified_search_terms.length}
    })
    
    if name_ids.length == 0 
      return {:common     => com_concepts,
              :scientific => sci_concepts,
              :errors     => errors}
    end
    
    agent_clause = ''
    if !options[:agent].nil? || (!options[:user].nil? && options[:user].is_admin?)
      agent_clause = %Q{
        LEFT JOIN (agents_resources ar
                   JOIN hierarchies_resources hr
                     ON (ar.resource_id = hr.resource_id
                         AND ar.resource_agent_role_id = #{ResourceAgentRole.content_partner_upload_role.id})
                   JOIN hierarchy_entries he2 ON (hr.hierarchy_id = he2.hierarchy_id))
          ON (he2.taxon_concept_id = tc.id)
      }
    end
    
    vetted_condition = options[:user].vetted ? "(tc.published=1 AND tc.vetted_id=#{Vetted.trusted.id})" : "tc.published=1"
    agent_condition =  options[:agent].nil? ? '' : "OR ar.agent_id=#{options[:agent].id}"
    if !options[:user].nil? && options[:user].is_admin?
      agent_condition = "OR ar.agent_id IS NOT NULL"
    end
    
    taxon_concept_ids = SpeciesSchemaModel.connection.execute(%Q{
      SELECT tcn.taxon_concept_id id, tcn.vern is_vern, tcn.preferred preferred,
             tcc.content_level content_level,
             n.string matching_string, n.italicized matching_italicized_string,
             he.hierarchy_id hierarchy_id
      FROM taxon_concept_names tcn
        STRAIGHT_JOIN names n ON (tcn.name_id = n.id)
        STRAIGHT_JOIN taxon_concepts tc ON (tc.id = tcn.taxon_concept_id)
        LEFT JOIN taxon_concept_content tcc ON (tcn.taxon_concept_id = tcc.taxon_concept_id)
        LEFT JOIN hierarchy_entries he ON (tcn.source_hierarchy_entry_id = he.id) #{agent_clause}
      WHERE tcn.name_id IN (#{name_ids.join(',')})
        AND (#{vetted_condition} #{agent_condition})
      ORDER BY preferred DESC
    }).all_hashes
    
    used_concept_ids = []
    sci_concepts = []
    com_concepts = []

    taxon_concept_ids.each do |result|
      if !used_concept_ids.include?(result['id'].to_i) || (result['hierarchy_id'].to_i == Hierarchy.default.id && result['preferred'].to_i == 1)
        
        # Remove existing concept representative if we have one from default hierarchy
        if result['hierarchy_id'].to_i == Hierarchy.default.id && result['preferred'].to_i == 1
          sci_concepts.delete_if { |concept| concept['id'] == result['id'] }
          com_concepts.delete_if { |concept| concept['id'] == result['id'] }
        end
        
        if result['is_vern'].to_i == 0
          sci_concepts << result
        else
          com_concepts << result
        end
        
        used_concept_ids << result['id'].to_i
      end
    end

    if taxon_concept_ids.length == 0
      errors ||= []
      errors << "There were no matches for the search term #{search_string}"
    end
    
    return {:common     => com_concepts,
            :scientific => sci_concepts,
            :errors     => errors}

  end
  
  def iucn
    return @iucn if !@iucn.nil?
    # Notice that we use find_by, not find_all_by.  We require that only one match (or no match) is found.
    # TODO - hack on [].flatten to handle two cases, which we currently have between prod and dev.  Fix this in the
    # next iteration (any after 2.9):
    my_iucn = DataObject.find_by_sql([<<EOIUCNSQL, id, [Resource.iucn].flatten.map(&:id)]).first

    SELECT distinct do.*
      FROM hierarchy_entries he
        JOIN taxa t ON (he.id = t.hierarchy_entry_id)
        JOIN harvest_events_taxa het ON (t.id = het.taxon_id)
        JOIN harvest_events hevt ON (het.harvest_event_id = hevt.id)
        JOIN data_objects_taxa dot ON (t.id = dot.taxon_id)
        JOIN data_objects do ON (dot.data_object_id = do.id)
      WHERE he.taxon_concept_id = ?
        AND hevt.resource_id IN (?)
        AND do.published = 1
      ORDER BY do.id desc
      LIMIT 1 # TaxonConcept.iucn

EOIUCNSQL
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

  # Pull text content by given category for taxa id.
  # Builds the content for a given category, or TocItem.
  # This method delegates custom TOC renderings to the
  # CategoryContentBuilder class
  def content_by_category(category_id, options = {})

    # Make toc_item point to a TocItem object
    if category_id.is_a?(TocItem)
      toc_item = category_id
    else
      toc_item = TocItem.find(category_id) rescue nil
    end
    return nil if toc_item.nil?

    # The Category content builder currently only builds
    # customized content. Text data objects is still 
    # handled by TaxonConcept#get_default_content

    ccb = CategoryContentBuilder.new
    options[:vetted] = current_user.vetted
    options[:taxon_concept_id] = id
    content = ccb.content_for(toc_item, options)
    content = get_default_content(toc_item) if content.nil?
    content
  end

  # This used to be singleton, but now we're changing the views (based on permissions) a lot, so I removed it.
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
    perform_filter =  !filter_hierarchy.nil?
    
    image_page = (options[:image_page] ||= 1).to_i
    images ||= DataObject.for_taxon(self, :image, :user => self.current_user, :agent => @current_agent, :filter_by_hierarchy => perform_filter, :hierarchy => filter_hierarchy, :image_page => image_page)
    @length_of_images = images.length # Caching this because the call to #images is expensive and we don't want to do it twice.
    
    #puts "this is the end of TaxonConcept.images"
    return images
  end

  # title and sub-title depend on expertise level of the user that is passed in (default to novice if none specified)
  def title(hierarchy = nil)
    return @title unless @title.nil?
    hierarchy ||= Hierarchy.default
    
    title = quick_scientific_name(:italicized, hierarchy)
    title = title.empty? ? name(:scientific) : title
    @title = title.firstcap
  end

  def subtitle(hierarchy = nil)
    return @subtitle unless @subtitle.nil?
    hierarchy ||= Hierarchy.default
    subtitle = quick_common_name(nil, hierarchy)
    subtitle = quick_scientific_name(:canonical, hierarchy) if subtitle.empty?
    subtitle = "<i>#{subtitle}</i>" unless subtitle.empty? or subtitle =~ /<i>/
    @subtitle = subtitle.empty? ? name() : subtitle
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
    sql = "SELECT taxon_concepts.* FROM taxon_concepts
    JOIN hierarchy_entries   ON taxon_concepts.id                    = hierarchy_entries.taxon_concept_id
    JOIN taxa                ON taxa.hierarchy_entry_id              = hierarchy_entries.id 
    JOIN data_objects_taxa   ON data_objects_taxa.taxon_id           = taxa.id
    JOIN data_objects        ON data_objects.id                      = data_objects_taxa.data_object_id
    WHERE data_objects.id IN (#{ ids.join(', ') }) 
      AND taxon_concepts.supercedure_id = 0
      AND taxon_concepts.published      = 1"
    TaxonConcept.find_by_sql(sql).uniq
  end

  # This could use name... but I only need it for searches, and ID is all that matters, there.
  def <=>(other)
    return id <=> other.id
  end

  # Rather than going through TaxonConceptName, this takes advantage of the HierarchyEntry id in the +taxa+ table.
  def taxa
    Taxon.find_by_sql([%Q{
      SELECT DISTINCT taxa.* 
        FROM hierarchy_entries
          JOIN taxa ON (taxa.hierarchy_entry_id = hierarchy_entries.id)
      WHERE hierarchy_entries.taxon_concept_id = ?
    }, self[:id]])
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

        xml.taxa {
          taxa.map{|x| x.visible_references.to_xml(:builder => xml, :skip_instruct => true)}
        }

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

  def self.common_names_for?(taxon_concept_id)
    return TaxonConcept.count_by_sql(['SELECT 1 FROM taxon_concept_names tcn 
                                        WHERE taxon_concept_id = ? 
                                          AND vern = 1 
                                        LIMIT 1',taxon_concept_id]) > 0
  end
  
  # Adds a single common name to this TC.
  # Options:
  #   +agent_id+::
  #     The id of the agent (which should be linked to a curator's user account) adding the name
  #   +language+::
  #     Language object to use for this name.  Default is Language.english
  #   +preferred+::
  #     Boolean to flag which name is preferred for this TC.  Default is true, but be careful that you only set one.
  # Returns:
  #   A three-element array, including:
  #     The Name object
  #     The Synonym object
  #     The TaxonConceptName object.
  def add_common_name(name, agent, options = {})
    language  = options[:language] || Language.unknown
    preferred = !!options[:preferred]
    relation  = SynonymRelation.find_by_label("common name")
    vern      = true
    name_obj  = generate_common_name(name)
    syn       = generate_synonym(name_obj, agent,
                                     :preferred => preferred,
                                     :language => language,
                                     :relation => relation)
    tcn       = generate_tc_name(name_obj, syn.id, 
                                     :preferred => preferred,
                                     :language => language,
                                     :vern => vern)
    set_preffered_when_known(language.id)
    [name_obj, syn, tcn]
  end

  def delete_common_name(taxon_concept_name)
    language_id = taxon_concept_name.language.id
    syn_id = taxon_concept_name.synonym.id
    TaxonConceptName.delete_all(:synonym_id => syn_id)
    AgentsSynonym.delete_all(:synonym_id => syn_id)
    Synonym.delete(syn_id)
    set_preffered_when_known(language_id)
  end

#####################
private
  def set_preffered_when_known(language_id)
    languages_to_skip = [Language.unknown].map {|l| l.id}
    return if languages_to_skip.include? language_id
    # if only one name left for the language -- make it preferred
    tcns = TaxonConceptName.find_all_by_taxon_concept_id_and_language_id(self.id, language_id)
    if tcns.size == 1
      tcn = tcns[0]
      tcn.preferred = 1
      SpeciesSchemaModel.connection.execute("UPDATE taxon_concept_names SET `preferred` = 1 where (language_id = #{tcn.language_id}) and (name_id = #{tcn.name_id}) AND (taxon_concept_id = #{tcn.taxon_concept_id}) AND (source_hierarchy_entry_id = #{tcn.source_hierarchy_entry_id})")
    end
  end

#####################
private
  
  def generate_common_name(name)
    name_obj = Name.find_by_string(name)
    if name_obj.blank?
      name_obj = Name.create_common_name(name)
    end
    name_obj
  end
  
  def generate_synonym(name_obj, agent, options = {})
    language  = options[:language] || Language.unknown
    synonym_relation = options[:relation] || SynonymRelation.synonym
    hierarchy = Hierarchy.eol_contributors 
    preferred = options[:preferred]
    synonym = Synonym.find_by_hierarchy_id_and_hierarchy_entry_id_and_language_id_and_name_id(
              hierarchy.id, 
              entry.id, 
              language.id, 
              name_obj.id)
    unless synonym
      synonym = Synonym.create(:name             => name_obj, 
                               :hierarchy        => hierarchy,
                               :hierarchy_entry  => entry, 
                               :language         => language,
                               :synonym_relation => synonym_relation,
                               :preferred        => preferred)
      AgentsSynonym.create(:agent      => agent,
                           :agent_role_id => AgentRole.contributor_id,
                           :synonym    => synonym,
                           :view_order    => 1)
    end
    synonym
  end

  # Note that if the TCN already exists, the user may end up confused because they cannot *edit* that TCN--it "belongs" to
  # another hierarchy.
  def generate_tc_name(name_obj, synonym_id, options = {})
    language  = options[:language]  || Language.unknown
    preferred = options[:preferred]
    vern      = options.has_key?(:vern) ? options[:vern] : true
    tcn       = TaxonConceptName.find_by_synonym_id(synonym_id)
    if tcn.blank?
      tcn = TaxonConceptName.create(:synonym_id => synonym_id, 
                                    :language => language,
                                    :name => name_obj,
                                    :preferred => preferred,
                                    :source_hierarchy_entry_id => entry.id,
                                    :taxon_concept => self,
                                    :vern => vern)
    end
    tcn
  end

  def alternate_classification_name(detail_level = :middle, language = Language.english, context = nil)
    #return col_he.nil? ? alternate_classification_name(detail_level, language, context) : col_he.name(detail_level, language, context)
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

