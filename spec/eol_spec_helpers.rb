require 'lib/eol_data'

module EOL::Spec
  module Helpers

    # get or set a variable that's stored on the spec (the describe block)
    # so it's cached between examples
    #
    # obviously, be careful with this one ... only use this if 
    # it makes sense to use this.  a good example is caching data 
    # that you want to access in multiple examples but which is 
    # expensive to create.
    #
    # before(:all) blocks can help with this too, except any database 
    # modifications that happen in before(:all) blocks will happen 
    # OUTSIDE the scope of transactions ... which is bad
    #
    def spec_variable name, value = :unset
      if value == :unset
        self.class.instance_variable_get "@#{ name.to_s }"
      else
        self.class.instance_variable_set "@#{ name.to_s }", value
      end
    end

    def login_content_partner options = { }
      f = request('/content_partner/login', :params => { 
          'agent[username]' => options[:username], 
          'agent[password]' => options[:password] })
    end

    def login_as options = { }
      if options.is_a? User # let us pass a newly created user (with an entered_password)
        options = { :username => options.username, :password => options.entered_password }
      end
      request('/account/authenticate', :params => { 
          'user[username]' => options[:username], 
          'user[password]' => options[:password] })
    end

    # returns a connection for each of our databases, eg: 1 for Data, 1 for Logging ...
    def all_connections
      # use_db lazy-loads its db list, so the classes in logging/ are ignored unless you reference one:
      CuratorActivity.first
      UseDbPlugin.all_use_dbs.map {|db| db.connection }
    end

    # call truncate_all_tables but make sure it only 
    # happens once in the Process
    def truncate_all_tables_once
      unless $truncated_all_tables_once
        $truncated_all_tables_once = true
        print "truncating tables ... "
        truncate_all_tables
        puts "done"
      end
    end

    def reset_auto_increment_on_tables_with_tinyint_primary_keys
      %w( agent_contact_roles agent_data_types agent_roles agent_statuses 
                audiences harvest_events resource_agent_roles ).
      map {|table| "ALTER TABLE `#{ table }` AUTO_INCREMENT=1; " }.each do |sql|
        SpeciesSchemaModel.connection.execute sql
      end
    end

    # truncates all tables in all databases
    def truncate_all_tables options = { }
      options[:verbose] ||= false
      all_connections.each do |conn|
        conn.tables.each   do |table|
          unless table == 'schema_migrations'
            puts "[#{conn.instance_eval { @config[:database] }}].`#{table}`" if options[:verbose]
            conn.execute "TRUNCATE TABLE`#{table}`"
          end
        end
      end
    end

    def recreate_normalized_names_and_links
      NormalizedName.truncate
      NormalizedLink.truncate
      Name.all.each {|name| NormalizedLink.parse! name }
    end

    # Builds a DataObject and creates all of the ancillary relationships.  Returns the DataObject.
    #
    # This takes three arguments.  The first is the type of the DataObject: acceptable values include 'Text',
    # 'Image', 'GBIF Image', 'Flash', and 'YouTube'.  The second argument is the description, since all
    # DataObject instances make use of this one.  The third argument is a hash of options.  Some key values are:
    #
    #   +content_partner+::
    #     If specified, a Resource, HarvestEvent, and all relationships between them will be created.
    #   +hierarchy_entry+::
    #     Which HE to link this object to. If missing, defaults to the last HE in the table, so be careful.
    #   +name+::
    #     Which Name object (q.v.) to link the Taxon to. 
    #   +num_comments+::
    #     How many comments to attach to this object.
    #   +scientific_name+::
    #     Which raw scientific name the content provider assigned to the Taxon.  Defaults to the HE's. 
    #   +taxon+::
    #     Which Taxon (q.v.) to link this to.  If missing, one will be created. 
    #   +toc_item+::
    #     If this is a 'Text' type, this specifies which TocItem to link this to. If left blank, one is randomly
    #     chosen.
    #
    # Any other options on this method will be passed directly to the DataObject#gen method (for example,
    # lattitude, longitude, and the like).
    #
    # NOTE - I am not setting the mime type yet.  We never use it.  NOTE - There are no models for all the
    # refs_* tables, so I'm ignoring them.  TODO - in several places, I call Model.all.rand.  This is less than
    # efficient and needs optimization. I'm presently banking on very small arrays!  :)
    def build_data_object(type, desc, options = {})

      attributes = {:data_type   => DataType.find_by_label(type),
                    :description => desc,
                    :visibility  => Visibility.visible,
                    :vetted      => Vetted.trusted,
                    :license     => License.all.rand}

      agent_role      = options.delete(:agent_role)      || 'Author'
      agent_role      = AgentRole.find_by_label(agent_role) || AgentRole.first
      content_partner = options.delete(:content_partner)
      event           = options.delete(:event)
      he              = options.delete(:hierarchy_entry) || HierarchyEntry.last
      name            = options.delete(:name)            || Name.gen
      num_comments    = options.delete(:num_comments)    || 1
      scientific_name = options.delete(:scientific_name) || he.name(:expert) || Factory.next(:scientific_name)
      taxon           = options.delete(:taxon)
      toc_item        = options.delete(:toc_item)
      toc_item      ||= TocItem.find_by_sql('select * from table_of_contents where id!=3').rand if type == 'Text'
      taxon         ||= Taxon.gen(:name => name, :hierarchy_entry => he, :scientific_name => scientific_name)

      options[:object_cache_url] ||= Factory.next(:image) if type == 'Image'

      dato            = DataObject.gen(attributes.merge(options))

      DataObjectsTaxon.gen(:data_object => dato, :taxon => taxon)

      if type == 'Image'
        if dato.visibility == Visibility.visible and dato.vetted == Vetted.trusted
          TopImage.gen :data_object => dato, :hierarchy_entry => taxon.hierarchy_entry
        else
          TopUnpublishedImage.gen :data_object => dato, :hierarchy_entry => he
        end
      elsif type == 'Text'
        DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => toc_item)
      end
      num_comments.times { Comment.gen(:parent => dato, :user => User.all.rand) }

      # TODO - Really, we always want these things.  There's no such thing as a "floating" data object.
      # Either it is related to a user (text object submitted through website) or a HarvestEvent.
      #
      # However, that takes a LOT of CPU cycles (and DB time), so what I would like to do is have a
      # "default" event (and content partner) which, unless specified, is attached.
      agent = nil
      if not event.nil? 
        DataObjectsHarvestEvent.gen(:harvest_event => event, :data_object => dato)
      elsif not content_partner.nil?
        agent_resource = content_partner.agent.agents_resources.detect do |ar|
          ar.resource_agent_role_id == ResourceAgentRole.content_partner_upload_role.id
        end
        if agent_resource.nil?
          agent = content_partner.agent
          agent_resource = AgentsResource.gen(:agent => agent,
                                              :resource_agent_role => ResourceAgentRole.content_partner_upload_role)
        end
        event    = HarvestEvent.gen(:resource => agent_resource.resource)
        pp event
        DataObjectsHarvestEvent.gen(:harvest_event => event, :data_object => dato)
      end
      agent ||= event.nil? ? Agent.gen : event.resource.agents.first

      AgentsDataObject.gen(:agent => agent, :agent_role => agent_role, :data_object => dato)

      return dato

    end

    # Builds a HierarchyEntry and creates all of the ancillary relationships.  Returns the HierarchyEntry.
    #
    # This takes four arguments.  The first is the depth of the HE (0 for kingdom, and so on), defaulting to
    # 0. The second is the taxon concept that this relates to. The third argument is the Name object associated
    # with this HE.  The last is a hash of options.  Some possible values:
    #
    #   +hierarchy+::
    #     Which Hierarchy to link this to.  Defaults to... uhhh... the default (Hierarchy#default).
    #   +parent_id+::
    #     Which HierarchyEntry (by *ID*, not object) this links to.
    #
    # TODO LOW_PRIO - the arguments to this method are lame and should be options with reasonable defaults.
    def build_hierarchy_entry(depth, tc, name, options = {})
      he    = HierarchyEntry.gen(:hierarchy     => options[:hierarchy] || Hierarchy.default, # TODO - This should *really* be the H associated with the Resource that's being "harvested"... technically, CoL shouldn't even have HEs...
                                 :parent_id     => options[:parent_id] || 0,
                                 :identifier    => options[:identifier] || '', # This is the foreign ID native to the Resouce, not EOL.
                                 :depth         => depth,
                                 :rank_id       => depth + 1, # Cheating. As long as *we* created Ranks with a scenario, this works.
                                 :taxon_concept => tc,
                                 :name          => name)
      HierarchiesContent.gen(:hierarchy_entry => he, :text => 1, :image => 1, :content_level => 4, :gbif_image => options[:map] ? 1 : 0,
                             :youtube => 1, :flash => 1)
      # TODO - Create two AgentsHierarchyEntry(ies); you want "Source Database" and "Compiler" as roles
      return he
    end

    # == Options:
    #
    # These all have intelligent(ish) default values, so just specify those values that you feel are really salient. Note that a TC will
    # NOT have a map or an IUCN status unless you specify options that create them.
    #
    #   +attribution+::
    #     String to be used in scientific name as attribution
    #   +canonical_form+::
    #     String to use for canonical form (all names will reference this)
    #   +comments+::
    #     Array of hashes.  Each hash can have a +:body+ and +:user+ key.
    #   +common_name+::
    #     String to use for thre preferred common name
    #   +depth+::
    #     Depth to apply to the attached hierarchy entry.  Don't supply this AND rank.
    #   +flash+::
    #     Array of flash videos, each member is a hash for the video options.  The keys you will want are
    #     +:description+ and +:object_cache_url+.
    #   +id+::
    #     Forces the ID of the TaxonConcept to be what you specify, useful for exemplars.
    #   +images+::
    #     Array of hashes.  Each hash may have the following keys: +:description+, +:hierarchy_entry+,
    #     +:object_cache_url+, +:taxon+, +:vetted+, +:visibility+ ...These are the args used to call
    #     #build_data_object
    #   +italicized+::
    #     String to use for preferred scientific name's italicized form.
    #   +iucn_status+::
    #     String to use for IUCN description, OR just set to true if you want a random IUCN status instead.
    #   +gbif_map_id+::
    #     The ID to use for the Map Data Object.
    #   +parent_hierarchy_entry_id+::
    #     When building the associated HierarchyEntry, this id will be used for its parent.
    #   +rank+::
    #     String form of the Rank you want this TC to be.  Default 'species'.
    #   +scientific_name+::
    #     String to use for the preferred scientific name.
    #   +toc+::
    #     An array of hashes.  Each hash may have a +:toc_item+ key and a +:description+ key.
    #   +youtube+::
    #     Array of YouTube videos, each member is a hash for the video options.  The keys you will want are
    #     +:description+ and +:object_cache_url+.
    def build_taxon_concept(options = {})

      # TODO - Create a harvest event and a resource (status should be published) (and the resource needs a hierarchy, which we use for
      # the HEs)

      attri       = options[:attribution] || Factory.next(:attribution)
      common_name = options[:common_name] || Factory.next(:common_name)
      canon       = options[:canonical_form] || Factory.next(:scientific_name)
      complete    = options[:scientific_name] || "#{canon} #{attri}".strip
      cform = CanonicalForm.find_by_string(canon) || CanonicalForm.gen(:string => canon)
      sname = Name.gen(:canonical_form => cform, :string => complete,
                       :italicized     => options[:italicized] || "<i>#{canon}</i> #{attri}".strip)
      # TODO - You don't always need a common name, and in fact most don't; default should be NOT to have one
      # TODO - This should also create an entry in Synonyms (see below) (don't need agents_synonyms though)
      cname = Name.gen(:canonical_form => cform, :string => common_name, :italicized => common_name)

      # TODO - Normalize names ... when harvesting is done, this is done on-the-fly, so we should do it here.

      # TODO - in the future, we may want to be able to muck with the vetted *and* the published fields...
      tc    = nil # scope...
      # HACK!  We need to force the IDs of one of the TaxonConcepts, so that the exmplar array isn't empty.  I
      # hate to do it this way, but, alas, this is how it currently works:
      if options[:id]
        tc = TaxonConcept.find(options[:id]) rescue nil
        if tc.nil?
          tc = TaxonConcept.gen(:vetted => Vetted.trusted)
          TaxonConcept.connection.execute("UPDATE taxon_concepts SET id = #{options[:id]} WHERE id = #{tc.id}")
          tc = TaxonConcept.find(options[:id])
        end
      else
        tc = TaxonConcept.gen(:vetted => Vetted.trusted)
      end

      # Note that this assumes the ranks are *in order* which is ONLY true with foundation loaded!
      depth = options[:depth] || Rank.find_by_label(options[:rank] || 'species').id - 1 # This is an assumption...
      he    = build_hierarchy_entry(depth, tc, sname, :parent_id => options[:parent_hierarchy_entry_id])
      TaxonConceptName.gen(:preferred => true, :vern => false, :source_hierarchy_entry_id => he.id,
                           :language => Language.scientific, :name => sname, :taxon_concept => tc)
      TaxonConceptName.gen(:preferred => true, :vern => true, :source_hierarchy_entry_id => he.id,
                           :language => Language.english, :name => cname, :taxon_concept => tc)
      # TODO - create the Synonym here, with the Language of English, the SynonymRelation of Common Name, and the HE we just
      # created, and preferred...
      # NOTE: when we denormalize the taxon_concept_names table, we should be looking at Synonyms as well as Names.
      curator = Factory(:curator, :curator_hierarchy_entry => he)

      # Array with three empty hashes (default #), which we will populate with defaults:
      comments = options[:comments] || [{}, {}]
      comments.each do |comment|
        comment[:body]  ||= "This is a witty comment on the #{canon} taxon concept. Any resemblance to comments real" +
                            'or imagined is coincidental.'
        comment[:user] ||= User.all.rand
        Comment.gen(:parent => tc, :parent_type => 'taxon_concept', :body => comment[:body], :user => comment[:user])
      end

      # TODO - add some alternate names, including at least one in another language.
      # TODO - create alternate scientific names... just make sure the relation makes sense and the language_id is either 0 or
      # Language.scientific.

      taxon = Taxon.gen(:name => sname, :hierarchy_entry => he, :scientific_name => complete) # Okay that we don't set kingdom, phylum, etc
      # TODO - Need a HarvestEventsTaxon entry here
      # TODO - Create some references here ... just a string and an associated identifier (like a URL)

      images = [] # This is used to build the RandomTaxon
      if options[:images].nil?
        options[:images] = [{:num_comments => 12}] # One "normal" image, lots of comments, everything else default.
        # So, every TC (which doesn't have a predefined list of images) will have each of the following, making
        # testing easier:
        options[:images] << {:description => 'untrusted', :object_cache_url => Factory.next(:image),
                             :vetted => Vetted.untrusted}
        options[:images] << {:description => 'unknown',   :object_cache_url => Factory.next(:image),
                             :vetted => Vetted.unknown}
        options[:images] << {:description => 'invisible', :object_cache_url => Factory.next(:image),
                             :visibility => Visibility.invisible}
        options[:images] << {:description => 'preview', :object_cache_url => Factory.next(:image),
                             :visibility => Visibility.preview}
        options[:images] << {:description => 'invisible, unknown', 
                             :object_cache_url => Factory.next(:image), :visibility => Visibility.invisible,
                             :vetted => Vetted.unknown}
        options[:images] << {:description => 'invisible, untrusted', 
                             :object_cache_url => Factory.next(:image), :visibility => Visibility.invisible,
                             :vetted => Vetted.untrusted}
        options[:images] << {:description => 'preview, unknown', 
                             :object_cache_url => Factory.next(:image), :visibility => Visibility.preview,
                             :vetted => Vetted.unknown}
        options[:images] << {:description => 'inappropriate', 
                             :object_cache_url => Factory.next(:image), :visibility => Visibility.inappropriate}
      end
      options[:images].each do |img|
        description             = img.delete(:description) || Faker::Lorem.sentence
        img[:taxon]           ||= taxon
        images << build_data_object('Image', description, img)
      end
      
      flash_options = options[:flash] || [{}] # Array with one empty hash, which we will populate with defaults:
      flash_options.each do |flash_opt|
        flash_opt[:description]      ||= Faker::Lorem.sentence
        flash_opt[:object_cache_url] ||= Factory.next(:flash)
        build_data_object('Flash', flash_opt[:description], :taxon => taxon,
                          :object_cache_url => flash_opt[:object_cache_url])
      end

      youtube_options = options[:youtube] || [{}] # Array with one empty hash, which we will populate with defaults:
      youtube_options.each do |youtube_opt|
        youtube_opt[:description]      ||= Faker::Lorem.sentence
        youtube_opt[:object_cache_url] ||= Factory.next(:youtube)
        build_data_object('YouTube', youtube_opt[:description], :taxon => taxon,
                          :object_cache_url => youtube_opt[:object_cache_url])
      end

      if options[:iucn_status]
        iucn_status = options[:iucn_status] == true ? Factory.next(:iucn) : options[:iucn_status]
        build_iucn_entry(tc, iucn_status, :depth => depth)
      end

      if options[:gbif_map_id] 
        gbif_he = build_hierarchy_entry(depth, tc, sname, :hierarchy => gbif_hierarchy, :map => true, :identifier => options[:gbif_map_id])
        gbif_taxon = Taxon.gen(:name => sname, :hierarchy_entry => he, :scientific_name => complete)
        HarvestEventsTaxon.gen(:taxon => gbif_taxon, :harvest_event => gbif_harvest_event)
      end

      if options[:toc].nil?
        options[:toc] = [{:toc_item => TocItem.overview, :description => "This is an overview of the <b>#{canon}</b> hierarchy entry."},
                         {:toc_item => TocItem.find_by_label('Description'), :description => "This is an description of the <b>#{canon}</b> hierarchy entry."}]
        # Add more toc items:
        (rand(4)+1).times do
          options[:toc] << {} # Default values are applied below.
        end
      end
      options[:toc].each do |toc_item|
        toc_item[:toc_item]    ||= TocItem.all.rand
        toc_item[:description] ||= Faker::Lorem.paragraph
        build_data_object('Text', toc_item[:description], :taxon => taxon, :toc_item => toc_item[:toc_item])
      end
      # We're missing the info items.  Technically, the toc_item would be referenced by looking at the info items (creating any we're
      # missing).  TODO - we should build the info item first and let the toc_item resolve from that.
      # TODO BHL - just create an entry in each of the four special tables, linked to any of the names.
      # TODO Outlinks: create a Collection related to any agent, and then give it a mapping with a foreign_key that links to some external
      # site. (optionally, you could use collection.uri and replace the FOREIGN_KEY bit)

      # TODO - we really don't want to denomalize the names, so remove them (but check that this will work!)
      RandomTaxon.gen(:language => Language.english, :data_object => images.last, :name_id => sname.id,
                      :image_url => images.last.object_cache_url, :name => sname.italicized, :content_level => 4,
                      :taxon_concept => tc, :common_name_en => cname.string,
                      :thumb_url => images.first.object_cache_url) # TODO - not sure thumb_url is right.
      return tc
    end

    # Create a data object in the IUCN hierarchy. Can take options for :hierarchy and :event, both of which default to the usual IUCN
    # values (which will be created if they don't exist already). Can also take :depth, though I'm not sure that matters much yet.  :name
    # is another option (note this is a Name *object*, not a string); it will default to the TaxonConcept's first name.  
    #
    # Returns the data object built.
    def build_iucn_entry(tc, status, options = {})
      options[:hierarchy] ||= iucn_hierarchy
      options[:event]     ||= iucn_harvest_event
      options[:depth]     ||= 3 # Arbitrary, really.
      options[:name]      ||= tc.taxon_concept_names.first.name
      iucn_he = build_hierarchy_entry(options[:depth], tc, options[:name], :hierarchy => options[:hierarchy]) 
      iucn_taxon = Taxon.gen(:name => options[:name], :hierarchy_entry => iucn_he, :scientific_name => options[:name].string)
      HarvestEventsTaxon.gen(:taxon => iucn_taxon, :harvest_event => options[:event])
      build_data_object('IUCN', status, :taxon => iucn_taxon, :published => 1)
    end

    def find_or_build_hierarchy(label)
      Hierarchy.find_by_label(label) || Hierarchy.gen(:label => label)
    end

    def find_or_build_resource(title)
      Resource.find_by_title(title) || Resource.gen(:title => title)
    end

    def find_or_build_harvest_event(resource)
      HarvestEvent.find_by_resource_id(resource.id) || HarvestEvent.gen(:resource => resource)
    end

    def gbif_hierarchy
      find_or_build_hierarchy('GBIF')
    end

    def iucn_hierarchy
      find_or_build_hierarchy('IUCN')
    end

    def gbif_harvest_event
      find_or_build_harvest_event(find_or_build_resource('Initial GBIF Import'))
    end

    def iucn_harvest_event
      find_or_build_harvest_event(Resource.iucn[0])
    end

  end
end

class ActiveRecord::Base

  # truncate's this model's table
  def self.truncate
    connection.execute "TRUNCATE TABLE #{ table_name }"
  rescue => ex
    puts "#{ self.name }.truncate failed ... does the table exist?  #{ ex }"
  end

end

# MONKEY-PATCHING OUR MODELS...
#
# The problem is that we have *no* methods that make relating data between models easy... because this project is
# largely read-only, so the methods have *no use* in production.  Therefore, we monkey-patch them here (TODO - move
# these to a separate file) in order to have these methods available ONLY when we're testing. This keeps us from
# worrying about the methods screwing things up in production: they don't exist.
# 
# Please *try* and KEEP THESE ALPHABETICAL for now.  When we have too many, we'll break them up into files, but that
# will make loading much more complicated.

Ref.class # lame way of getting rails to auto-load the class.  If we skip this step, Ref is defined here, and we 
          # never load the model!
class Ref
  def add_identifier(type, identifier)
    type = RefIdentifierType.find_by_label(type) || RefIdentifierType.gen(:label => type)
    # TODO - I can take off the :ref => self, right?  For now, being safe.
    self.ref_identifiers << RefIdentifier.gen(:ref_identifier_type => type, :identifier => identifier, :ref => self)
  end
end
