# Represents the vague idea of a Taxon.
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
class TaxonConcept < SpeciesSchemaModel

  #TODO belongs_to :taxon_concept_content
  belongs_to :vetted

  has_many :hierarchy_entries
  has_many :last_curated_dates
  has_many :taxon_concept_names
  has_many :comments, :as => :parent, :attributes => true
  has_many :names, :through => :taxon_concept_names
  has_many :ranks, :through => :hierarchy_entries
  # The following are not (yet) possible, because tcn has a three-part Primary key.
  # has_many :taxa, :through => :names, :source => :taxon_concept_names
  # has_many :mappings, :through => :names, :source => :taxon_concept_names

  # These are methods that are specific to a hierarchy, so we have to handle them through entry:
  delegate :kingdom, :to => :entry
  delegate :children_hash, :to => :entry
  delegate :ancestors_hash, :to => :entry
  delegate :find_default_hierarchy_ancestor, :to => :entry
  
  has_one :taxon_concept_content

  #delegate :content_level, :to => :entry # TODO remove this
  #TODO delegate :content_level, :to => :taxon_concept_content

  attr_accessor :includes_unvetted # true or false indicating if this taxon concept has any unvetted/unknown data objects

  ##################################### 
  # The following are the "nice" methods, which we want to publically expose.  ...As opposed to the down-and-dirty stuff that we
  # want to shamefully hide.  These are the methods from which we can build nice, clean objects to serve to the general public:

  # The canonical form is the simplest string we can use to identify a species--no variations, no attribution, nothing fancy:
  def canonical_form
    return name(:canonical)
  end

  # The common name will defaut to the current user's language.
  def common_name
    quick_common_name
  end

  # Curators are those users who have special permission to "vet" data objects associated with a TC, and thus get extra credit on
  # their associated TC pages. This method returns an Array of those users.  If you want a Set, call #approved_curators.
  def curators
    approved_curators.to_a
  end

  # The International Union for Conservation of Nature keeps a status for most known species, representing how endangered that
  # species is.  This will default to "unknown" for species that are not being tracked.
  def iucn_conservation_status
    return iucn.description
  end

  # Return a list of data objects associated with this TC's Overview toc (returns nil if it doesn't have one)
  def overview
    return content_by_category(TocItem.overview)[:data_objects]
  end

  # The scientific name for a TC will be italicized if it is a species (or below) and will include attribution and varieties, etc:
  def scientific_name
    quick_scientific_name(species_or_below? ? :italicized : :normal)
  end

  # pull list of categories for given taxa id
  def table_of_contents(options = {})
    return @table_of_contents ||= TocItem.toc_for(id, :agent => @current_agent, :user => current_user, :agent_logged_in => options[:agent_logged_in])
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
    entry.ancestors.map {|h| TaxonConcept.find(h.taxon_concept_id) } # Long-winded, but we *cache* these, and so the he.taxon_concept
                                                                     # relationship doesn't work with disk_store.  Stupid YAML! # TODO - fix
  end

  # Get a list of TaxonConcept models that are children to this one.
  #
  # Same caveats as #ancestors (q.v.)
  def children
    entry.children.map(&:taxon_concept)
  end

  # Get a list of some of our best TaxonConcept examples.  Results will be sorted by scientific name.
  #
  # The sorting is actually a moderately expensive operation, so this is cached.
  #
  # Lastly, note that the TaxonConcept IDs are hard-coded to our production database. TODO - move those IDs to a
  # table somewhere.
  def self.exemplars
    YAML.load(Rails.cache.fetch('taxon_concepts/exemplars') do
      TaxonConcept.find(:all, :conditions => ['id IN (?)',
        [910093, 1009706, 912371, 976559, 597748, 1061748, 373667, 482935, 392557,
         484592, 581125, 467045, 593213, 209984, 795869, 1049164, 604595, 983558,
         253397, 740699, 1044544, 802455, 1194666]]).sort_by(&:quick_scientific_name).to_yaml
        # JRice removed 2485151 because it was without content.  There is a bug for this, not sure of the #
    end)
  end

  ##################################### 
  # The rest of these methods are shamefully complex and probably require serious refactoring.

  # Try not to call this unless you know what you're doing.  :) See scientific_name and common_name instead.
  #
  # That said, this method allows you to get other variations on a name.  See HierarchyEntry#name, to which this is really
  # delegating, unless there is no entry in the default Hierarchy, in which case, see #alternate_classification_name.
  #
  # (Hey, I warned you these methods were ugly.)
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
    @current_user = who
  end

  def canonical_form_object
    return entry.canonical_form
  end

  # If *any* of the associated HEs are species or below, we consider this to be a species:
  def species_or_below?
    hierarchy_entries.detect {|he| he.species_or_below? }
  end

  def alternate_classification_name(detail_level = :middle, language = Language.english, context = nil)
    #return col_he.nil? ? alternate_classification_name(detail_level, language, context) : col_he.name(detail_level, language, context)
    self.hierarchy_entries[0].name(detail_level, language, context).firstcap rescue '?-?'
  end

  def in_hierarchy(search_hierarchy_id = 0)
    enries = hierarchy_entries.detect {|he| he.hierarchy_id == search_hierarchy_id }
    return enries.nil? ? false : true
  end

  # Because nested has_many_through won't work with CPKs:
  def mappings
    YAML.load(Rails.cache.fetch("taxon_concepts/#{self.id}/mappings") do
      Mapping.for_taxon_concept_id(self.id).sort_by {|m| m.id }.to_yaml
    end)
  end

  # I chose not to make this singleton since it should really only ever get called once:
  def ping_host_urls
    host_urls = []
    mappings.each do |mapping|
      host_urls << mapping.ping_host_url unless mapping.collection.nil? or mapping.ping_host? == false 
    end
    return host_urls
  end

  def approved_curators
    approved = Set.new
    self.hierarchy_entries.each do |he|
      approved.merge he.approved_curators
    end
    return approved
  end

  def acting_curators
    acting = Set.new
    self.hierarchy_entries.each do |he|
      acting.merge he.acting_curators
    end
    return acting 
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
      hierarchy_entries[0] ||
      raise(Exception.new("Taxon concept must have at least one hierarchy entry"))
  end

  # We do have some content that is specific to COL, so we need a method that will ALWAYS reference it:
  def col_entry
    return @col_entry unless @col_entry.nil?
    hierarchy_id = Hierarchy.default.id
    return @col_entry = hierarchy_entries.detect{ |he| he.hierarchy_id == hierarchy_id }
  end

  def current_agent=(agent)
    @current_agent = agent
  end
  
  def available_media
    images = video = map = false
    # TODO - JRice believes these rescues are bad.  They are--I assume--in here because sometimes there is no
    # hierarchies_content.  However, IF there is one AND we get some other errors, then A) we're not handling them,
    # and B) The value switches to false when it may have been true from a previous hierarchies_content.
    hierarchy_entries.each do |entry|
      images = true if entry.hierarchies_content.image != 0 || entry.hierarchies_content.child_image != 0 rescue images
      video = true if entry.hierarchies_content.flash != 0 || entry.hierarchies_content.youtube != 0 rescue video
      map = true if entry.hierarchies_content.gbif_image != 0 rescue map
    end
    
    map = false if map and gbif_map_id == empty_map_id # The "if map" avoids unecessary db hits; keep it.
    
    {:images => images,
     :video  => video,
     :map    => map }
  end

  def has_name?
    return content_level != 0
  end

  def quick_common_name(language = nil)
    language ||= current_user.language
    common_name_results = SpeciesSchemaModel.connection.select_values("SELECT n.string FROM taxon_concept_names tcn JOIN names n ON (tcn.name_id=n.id) WHERE tcn.taxon_concept_id=#{id} AND language_id=#{language.id} AND preferred=1 LIMIT 1")
    if common_name_results.empty?
      return ''
    end
    common_name_results[0].firstcap
  end
  
  def quick_scientific_name(type = :normal)

    scientific_name_results = []

    search_type = case type
      when :italicized  then {:name_field => 'n.italicized', :also_join => ''}
      when :canonical   then {:name_field => 'cf.string',    :also_join => 'JOIN canonical_forms cf ON (n.canonical_form_id=cf.id)'}
      else                   {:name_field => 'n.string',     :also_join => ''}
    end

    scientific_name_results = SpeciesSchemaModel.connection.execute(
      "SELECT #{search_type[:name_field]} name, he.hierarchy_id source_hierarchy_id
       FROM taxon_concept_names tcn JOIN names n ON (tcn.name_id=n.id) #{search_type[:also_join]}
         LEFT JOIN hierarchy_entries he ON (tcn.source_hierarchy_entry_id=he.id)
       WHERE tcn.taxon_concept_id=#{id} AND vern=0 AND preferred=1").all_hashes

    final_name = ''
    
    # This loop is to check to make sure the default hierarchy's preferred name takes precedence over other hierarchy's preferred names 
    scientific_name_results.each do |result|
      if final_name == '' || result['source_hierarchy_id'].to_i == Hierarchy.default.id
        final_name = result['name'].firstcap
      end
    end
    
    return final_name

  end
  
  # Some TaxonConcepts are "superceded" by others, and we need to follow the chain as far as we can (up to a sane limit): 
  def self.find_with_supercedure(*args)
    concept = TaxonConcept.find_without_supercedure(*args)
    return nil if concept.nil?
    id = args[0]
    return concept unless id =~ /^\d+$/
    attempts = 6
    while concept.supercedure_id != 0 and attempts <= 6
      concept = TaxonConcept.find_without_supercedure(concept.supercedure_id, *args[1..-1])
      attempts += 1
    end
    return concept
  end
  class << self; alias_method_chain :find, :supercedure ; end

  def self.quick_search(search_string, options = {})
    options[:user]            ||= User.create_new
    
    # TODO - insert into search terms, popular searches, and the like.
    
    search_terms = search_string.downcase.gsub(/\s+/, ' ').strip.split(/[ -&:\\'?;]+| and /)
    
    sci_concepts  = []
    com_concepts  = []
    errors       = nil
    num_matches  = {}
    
    
    modified_search_terms = []
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
    
    name_ids = SpeciesSchemaModel.connection.select_values("SELECT name_id, count(*) FROM normalized_names nn STRAIGHT_JOIN normalized_links nl ON (nn.id=nl.normalized_name_id) WHERE (#{modified_search_terms.join(' OR ')}) AND nl.normalized_qualifier_id=1 GROUP BY name_id HAVING count(*)>=#{modified_search_terms.length}")
    
    if name_ids.length == 0 
      return {:common     => com_concepts,
              :scientific => sci_concepts,
              :errors     => errors}
    end
    
    
    agent_clause = ''
    if !options[:agent].nil? || (!options[:user].nil? && options[:user].is_admin?)
      agent_clause = "LEFT JOIN (agents_resources ar JOIN hierarchies_resources hr ON (ar.resource_id=hr.resource_id AND ar.resource_agent_role_id = #{ResourceAgentRole.content_partner_upload_role.id}) JOIN hierarchy_entries he2 ON (hr.hierarchy_id=he2.hierarchy_id)) ON (he2.taxon_concept_id=tc.id)"
    end
    
    vetted_condition = options[:user].vetted ? "(published=1 AND tc.vetted_id=#{Vetted.trusted.id})" : "published=1"
    agent_condition =  options[:agent].nil? ? '' : "OR ar.agent_id=#{options[:agent].id}"
    if !options[:user].nil? && options[:user].is_admin?
      agent_condition = "OR ar.agent_id IS NOT NULL"
    end
    
    taxon_concept_ids = SpeciesSchemaModel.connection.execute("SELECT tcn.taxon_concept_id id, tcn.vern is_vern, tcn.preferred preferred, tcc.content_level content_level, n.string matching_string, n.italicized matching_italicized_string, he.hierarchy_id hierarchy_id FROM taxon_concept_names tcn STRAIGHT_JOIN names n ON (tcn.name_id=n.id) STRAIGHT_JOIN taxon_concepts tc ON (tc.id = tcn.taxon_concept_id) LEFT JOIN taxon_concept_content tcc ON (tcn.taxon_concept_id=tcc.taxon_concept_id) LEFT JOIN hierarchy_entries he ON (tcn.source_hierarchy_entry_id=he.id) #{agent_clause} WHERE tcn.name_id IN (#{name_ids.join(',')}) AND (#{vetted_condition} #{agent_condition}) ORDER BY preferred DESC").all_hashes
    
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
    # Notice that we use find_by, not find_all_by.  We require that only one match (or no match) is found.
    # TODO - hack on [].flatten to handle two cases, which we currently have between prod and dev.  Fix this in the
    # next iteration (any after 2.9):
    my_iucn = DataObject.find_by_sql([<<EOIUCNSQL, id, [Resource.iucn].flatten.map(&:id)]).first

    SELECT distinct do.*
      FROM taxon_concept_names tcn
        JOIN taxa t ON (tcn.name_id=t.name_id)
        JOIN harvest_events_taxa het ON (t.id=het.taxon_id)
        JOIN harvest_events he ON (het.harvest_event_id=he.id)
        JOIN data_objects_taxa dot ON (t.id=dot.taxon_id)
        JOIN data_objects do ON (dot.data_object_id=do.id)
      WHERE tcn.taxon_concept_id = ?
        AND he.resource_id IN (?)
        AND published = 1
      LIMIT 1 # TaxonConcept.iucn

EOIUCNSQL
    temp_iucn = my_iucn.nil? ? DataObject.new(:source_url => 'http://www.iucnredlist.org/', :description => 'NOT EVALUATED') : my_iucn
    temp_iucn.instance_eval { def agent_url; return Agent.iucn.homepage; end }
    return temp_iucn
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
    return entry(hierarchy_id).ancestors
  end

  def classification_attribution
    return entry.classification_attribution rescue ''
  end

  # pull content type by given category for taxa id 
  def content_by_category(category_id, options = {})
    category_id = category_id.id if category_id.is_a? TocItem
    toc_item = TocItem.find(category_id) rescue nil
    return nil if toc_item.nil?
    sub_name = toc_item.label.gsub(/\W/, '_').downcase
    return self.send(sub_name) if self.private_methods.include?(sub_name)
    return get_default_content(category_id, options)
  end

  # This used to be singleton, but now we're changing the views (based on permissions) a lot, so I removed it.
  def images(options = {})
    images = DataObject.for_taxon(self, :image, :user => current_user, :agent => @current_agent)
    @length_of_images = images.length # Caching this because the call to #images is expensive and we don't want to do it twice.
    return images
  end

  # title and sub-title depend on expertise level of the user that is passed in (default to novice if none specified)
  def title
    return @title unless @title.nil?
    title = quick_scientific_name(:italicized)
    @title = title.empty? ? name(:scientific) : title
  end

  def subtitle
    return @subtitle unless @subtitle.nil?
    subtitle = quick_common_name()
    subtitle = quick_scientific_name(:canonical) if subtitle.empty?
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
  
  def direct_ancestors
    he_all = []
    hierarchy_entries.each do |he|
      he_all << he
      parent = he.parent
      until parent.nil?
        he_all << parent
        parent = parent.parent
      end
    end
    he_all
  end

  def is_curatable_by? user
    he_all = direct_ancestors
    # hierarchy_entries_with_parents_above_clade = hierarchy_entries_with_parents
    # hierarchy_entries_with_parents_above_clade
    permitted = he_all.find {|entry| user.curator_hierarchy_entry_id == entry.id }
    if permitted then true else false end
  end

  # Gets an Array of TaxonConcept given DataObjects or their IDs
  #
  # this goes data_objects => data_objects_taxa => taxa => taxon_concept_names => taxon_concepts
  def self.from_data_objects *objects_or_ids
    ids = objects_or_ids.map {|o| if   o.is_a? DataObject 
                                  then o.id 
                                  else o.to_i end }
    return [] if ids.nil? or ids.empty? # Fix for EOLINFRASTRUCTURE-808
    sql = "select taxon_concepts.* from taxon_concepts
    join taxon_concept_names on taxon_concept_names.taxon_concept_id = taxon_concepts.id
    join taxa                on taxa.name_id                         = taxon_concept_names.name_id 
    join data_objects_taxa   on data_objects_taxa.taxon_id           = taxa.id
    join data_objects        on data_objects.id                      = data_objects_taxa.data_object_id
    where data_objects.id IN (#{ ids.join(', ') })"
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
    options[:methods] ||= [:canonical_form, :common_name, :iucn_conservation_status, :scientific_name]
    default_block = nil
    if options[:full]
      options[:methods] ||= [:canonical_form, :common_name, :iucn_conservation_status, :scientific_name]
      default_block = lambda do |xml|

        xml.overview { overview.to_xml(:builder => xml, :skip_instruct => true) }

        # Using tag! here because hyphens are not legal ruby identifiers.
        xml.tag!('table-of-contents') do
          toc.each do |ti|
            xml.item { xml.id ti.id ; xml.label ti.label }
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

#####################
private

  def empty_map_id
    return 1
  end

# =============== The following are methods specific to content_by_category

  # These should never be called; they're containers, not a leaf nodes:
  # references_and_more_information
  # evolution_and_systematics

  def common_names
    # NOTES: we had a notion of "unspecified" language.  Results were sorted.
    result = {
        :content_type  => 'common names',
        :category_name => 'Common Names',
        :items         => Name.find_by_sql([
                            'SELECT names.string, l.iso_639_1 language_label, l.label, l.name
                               FROM taxon_concept_names tcn JOIN names ON (tcn.name_id = names.id)
                                 LEFT JOIN languages l ON (tcn.language_id = l.id)
                               WHERE tcn.taxon_concept_id = ? AND vern = 1
                               ORDER BY language_label, string', id])
      }
    return result
  end

  def specialist_projects
    # I did not include these outlinks as data object in the traditional sense. For now, you'll need to go through the
    # collections and mappings tables to figure out which links pertain to the taxon (mappings has the name_id field). I
    # had some thoughts about including these in the taxa / data_object route, but I don't have plans to make this change
    # any time soon.
    # 
    # I had the table hierarchies_content which was supposed to let us know roughly what we had for each hierarchies_entry
    # (text, images, maps...). But, maybe it makes sense to cache the table of contents / taxon relationships as well as
    # media. Another de-normalized table. It may seem sloppy, but I'm sure we'll have to use de-normalized tables a lot in
    # this project.

#     mappings = Mapping.find_by_sql([<<EO_MAPPING_SQL, id, @current_user.vetted])
#       
#       SELECT DISTINCT m.*, a.full_name agent_full_name, c.*
#         FROM taxon_concept_names tcn
#           LEFT JOIN mappings m USING (name_id)
#           LEFT JOIN collections c ON (m.collection_id = c.id)
#           LEFT JOIN agents a ON (c.agent_id = a.id)
#         WHERE tcn.taxon_concept_id = ?
#           AND (c.vetted = 1 OR c.vetted = ?) # Specialist Projects / Mappings
# 
# EO_MAPPING_SQL
# 
#     results = []
#     mappings.each do |mapping|
#       collection_url = mapping.collection.uri.gsub!(/FOREIGNKEY/, mapping.foreign_key)
#       results << {
#         :agent_name       => mapping.agent_full_name || '[unspecified]',
#         :collection_title => mapping.collection.title,
#         :collection_link  => mapping.collection.link,
#         :url              => collection_url,
#         :icon             => mapping.collection.logo_url # FIX THIS LATER TODO
#       }
#     end
    
    mappings = SpeciesSchemaModel.connection.execute("SELECT DISTINCT m.id mapping_id, m.foreign_key foreign_key, a.full_name agent_name, c.title collection_title, c.link collection_link, c.logo_url icon, c.uri collection_uri FROM taxon_concept_names tcn JOIN mappings m ON (tcn.name_id=m.name_id) JOIN collections c ON (m.collection_id=c.id) JOIN agents a ON (c.agent_id=a.id) WHERE tcn.taxon_concept_id = #{id} AND (c.vetted=1 OR c.vetted=#{current_user.vetted}) GROUP BY c.id").all_hashes
    mappings.each do |mapping|
      mapping["url"] = mapping["collection_uri"].gsub!(/FOREIGNKEY/, mapping["foreign_key"])
    end
    
    sorted_mappings = mappings.sort_by { |mapping| mapping["agent_name"] }
    
    return {
          :category_name => 'Specialist Projects',
          :content_type => 'ubio_links',
          :category_name => 'Specialist Projects',
          :projects => sorted_mappings
        }

  end

  def biodiversity_heritage_library
    # items = ItemPage.find_by_sql([
    #                         'SELECT pt.title title, pt.url title_url, pt.details details, ip.*
    #                            FROM taxon_concept_names tcn 
    #                              JOIN page_names pn USING (name_id) 
    #                              JOIN item_pages ip ON (pn.item_page_id = ip.id)
    #                              JOIN title_items ti ON (ip.title_item_id = ti.id)
    #                              JOIN publication_titles pt ON (ti.publication_title_id = pt.id)
    #                            WHERE tcn.taxon_concept_id = ?
    #                             LIMIT 0,500 # TaxonConcept#bhl', id])  # TODO - sorting is wrong
    
    items = SpeciesSchemaModel.connection.execute("SELECT DISTINCT ti.id item_id, pt.title publication_title, pt.url publication_url, pt.details publication_details, ip.year item_year, ip.volume item_volume, ip.issue item_issue, ip.prefix item_prefix, ip.number item_number, ip.url item_url FROM taxon_concept_names tcn JOIN page_names pn ON (tcn.name_id=pn.name_id) JOIN item_pages ip ON (pn.item_page_id=ip.id) JOIN title_items ti ON (ip.title_item_id=ti.id) JOIN publication_titles pt ON (ti.publication_title_id=pt.id) WHERE tcn.taxon_concept_id = #{id} LIMIT 0,1000").all_hashes
    
    sorted_items = items.sort_by { |item| [item["publication_title"], item["item_year"], item["item_volume"], item["item_issue"], item["item_number"].to_i] }
    
    return {
          :content_type  => 'bhl',
          :category_name => 'Biodiversity Heritage Library',
          :items         => sorted_items
        }
  end

  def catalogue_of_life_synonyms
    return {
        :content_type  => 'synonyms',
        :category_name => 'Catalogue of Life Synonyms',
        :synonyms      => Synonym.by_taxon(col_entry.id).reject { |syn|
                            syn.synonym_relation.label == 'common name' }.sort_by {|syn| syn.name.string }
      }
  end

  def get_default_content(category_id, options)
    options.merge(:agent_id => @current_agent.id) unless @current_agent.nil?
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
      if data_object.sources.detect { |src| src.full_name == 'FishBase' }
        # TODO - We need a better way to choose which Agent to look at.  : \
        # TODO - We need a better way to choose which Collection to look at.  : \
        # TODO - We need a better way to choose which Mapping to look at.  : \
        foreign_key      = data_object.agents[0].collections[0].mappings[0].foreign_key
        (genus, species) = entry.name(:canonical).split()
        data_object.fake_author(
          :full_name => 'See FishBase for additional references',
          :homepage  => "http://www.fishbase.org/References/SummaryRefList.cfm?ID=#{foreign_key}&GenusName=#{genus}&SpeciesName=#{species}",
          :logo_url  => '')
      end
      override_data_objects << data_object
    end
    result[:data_objects] = override_data_objects
    return result
  end

# =============== END of content_by_category methods

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: taxon_concepts
#
#  id             :integer(4)      not null, primary key
#  supercedure_id :integer(4)      not null

