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

    def build_data_object(type, desc, options = {})
      dato_builder = EOL::DataObjectBuilder.new(type, desc, options)
      dato_builder.dato
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

    def build_taxon_concept(options = {})

      tc_builder = EOL::TaxonConceptBuilder.new(options)
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

    def find_or_build_resource(title, options = {})
      first_try = Resource.find_by_title(title) 
      return first_try unless first_try.nil?
      resource = Resource.gen(:title => title)
      if options[:agent]
        AgentsResource.gen(:agent => options[:agent], :resource => resource)
      end
      return resource
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

    def default_harvest_event
      find_or_build_harvest_event(find_or_build_resource('Test Framework Import', :agent => Agent.last))
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
