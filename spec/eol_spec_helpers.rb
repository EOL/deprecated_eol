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

      tc_builder = EOL::TaxonConceptBuilder.new(options)
      # TODO - Create a harvest event and a resource (status should be published) (and the resource needs a hierarchy, which we use for
      # the HEs)
      # TODO - Normalize names ... when harvesting is done, this is done on-the-fly, so we should do it here.
      tc_builder.gen_taxon_concept
      tc_builder.gen_name
      tc_builder.add_comments
      # TODO - add some alternate names, including at least one in another language.
      # TODO - create alternate scientific names... just make sure the relation makes sense and the language_id is either 0 or
      # Language.scientific.
      tc_builder.gen_taxon
      tc_builder.add_images
      tc_builder.add_videos
      tc_builder.add_map
      tc_builder.add_toc
      tc_builder.add_iucn
      tc_builder.gen_random_taxa
      tc_builder.gen_bhl
      return tc_builder.tc

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

Ref.class_eval do
  def add_identifier(type, identifier)
    type = RefIdentifierType.find_by_label(type) || RefIdentifierType.gen(:label => type)
    # TODO - I can take off the :ref => self, right?  For now, being safe.
    self.ref_identifiers << RefIdentifier.gen(:ref_identifier_type => type, :identifier => identifier, :ref => self)
  end
end

TaxonConcept.class_eval do
  # Quickly adds some user-submitted text to a TaxonConcept.
  #
  # Options are:
  #
  #   +description+:
  #     The actual text to add. Defaults to 'some random text' (literally).
  #   +language+:
  #     The language submitted, defaults to English.
  #   +license+:
  #     The license the text was submitted as.  Defaults to the last one in the DB.
  #   +title+:
  #     The title provided by the user (note none is required, and the default is none).
  #   +toc_item+:
  #     Under which TOC item it was added (careful, it's possible to add things to TocItems that the GUI disallows)
  #   +user+:
  #     The user who added it. Defaults to the last user in the DB.
  #   +vetted+:
  #     The text object will only be visible if the user is logged in with "All" rather than "Authoritative" mode.
  #     Set this to true if you want it to be visible to "Authoritative", or to remove the yellow background.
  def add_user_submitted_text(options)
    options = {:description => 'some random text',
               :user        => User.last,
               :toc_item    => TocItem.overview,
               :license     => License.last,
               :language    => Language.english,
               :vetted      => false
              }.merge(options)
    dato = DataObject.create_user_text({:taxon_concept_id => self.id,
                                        :data_objects_toc_category => { :toc_id => options[:toc_item].id },
                                        :data_object => {
                                          :object_title => options[:title],
                                          :description  => options[:description],
                                          :language_id  => options[:language].id,
                                          :license_id   => options[:license].id
                                        }
                                       }, options[:user])
    if options[:vetted]
      curator = self.curators.first
      curator ||= User.first
      dato.curate!(CuratorActivity.find_by_code('approve').id, curator)
    end
    return dato
  end
end
