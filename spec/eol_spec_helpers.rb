require 'lib/eol_data'
require 'nokogiri'

module EOL
  module Spec
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

      def login_content_partner(options = {})
        f = request('/content_partner/login', :params => { 
            'agent[username]' => options[:username], 
            'agent[password]' => options[:password],
            'remember_me' => options[:remember_me] || '' })
      end

      def login_as(options = {})
        if options.is_a? User # let us pass a newly created user (with an entered_password)
          options = { :username => options.username, :password => options.entered_password }
        end
        request('/account/authenticate', :params => { 
            'user[username]' => options[:username], 
            'user[password]' => options[:password],
            'remember_me' => options[:remember_me] || '' })
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
              count_rows = conn.execute("SELECT 1 FROM #{table} LIMIT 1")
              conn.execute "TRUNCATE TABLE`#{table}`" if count_rows.num_rows > 0
            end
          end
        end
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
      #   +identifier+::
      #     The "foreign key" that the Resource supplying this refers to this HE as, used for outlinking.
      #   +map+::
      #     If defined, this HE will be marked as having a map, otherwise marked as not having one.
      #   +parent_id+::
      #     Which HierarchyEntry (by *ID*, not object) this links to.
      #
      # TODO LOW_PRIO - the arguments to this method are lame and should be options with reasonable defaults.
      def build_hierarchy_entry(depth, tc, name, options = {})
        he = HierarchyEntry.gen(:hierarchy     => options[:hierarchy] || Hierarchy.default, # TODO - This should *really*
                                  # be the H associated with the Resource that's being "harvested"... technically, CoL
                                  # shouldn't even have Data Objects. Hierarchy.last may be clever enough, really.  I
                                  # just don't want to change this *right now*--I have other problems...
                                :parent_id     => options[:parent_id] || 0,
                                :identifier    => options[:identifier] || '',
                                :depth         => depth,
                                # Cheating. As long as *we* created Ranks with a scenario, this works:
                                :rank_id       => options[:rank_id] || 0,
                                :vetted_id       => options[:vetted_id] || Vetted.trusted.id,
                                :taxon_concept => tc,
                                :name          => name)
        HierarchiesContent.gen(:hierarchy_entry => he, :text => 1, :image => 1, :content_level => 4,
                               :map => options[:map] ? 1 : 0, :youtube => 1, :flash => 1)
        # TODO - Create two AgentsHierarchyEntry(ies); you want "Source Database" and "Compiler" as roles
        return he
      end

      def build_taxon_concept(options = {})
        tc_builder = EOL::TaxonConceptBuilder.new(options)
        return tc_builder.tc
      end

      # Curators are tricky... not just a plain model, but require some activity before they are "active":
      # The first argument is the TaxonConcept or HierarchyEntry to associate the curator to; the second argument is
      # the options hash to use when building the User model.
      def build_curator(entry, options = {})
        entry ||= Factory(:hierarchy_entry)
        tc = nil # scope
        if entry.class == TaxonConcept
          tc    = entry
          entry = tc.entry 
        end
        tc ||= entry.taxon_concept
        options = {
          :vetted                  => true,
          :curator_hierarchy_entry => entry,
          :curator_approved        => true,
          :curator_scope           => ''
        }.merge(options)

        # These two do "extra work", so I didn't want to use the merge on these (because they would be calculated even
        # if not used:
        options[:curator_verdict_by] ||= Factory(:user)
        options[:curator_verdict_at] ||= 48.hours.ago

        curator = User.gen(options)

        # A curator isn't credited until she actually DOES something, which is handled thusly:
        curator.last_curated_dates << LastCuratedDate.gen(:taxon_concept => tc, :user => curator)
        return curator
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
end

def DataObject.build_reharvested_dato(dato)
  new_dato = self.gen(
  :guid                   => dato.guid,
  :data_type              => dato.data_type,
  :mime_type              => dato.mime_type,
  :object_title           => dato.object_title,
  :language               => dato.language,
  :license                => dato.license,
  :rights_statement       => dato.rights_statement,
  :rights_holder          => dato.rights_holder,
  :bibliographic_citation => dato.bibliographic_citation,
  :source_url             => dato.source_url,
  :description            => dato.description,
  :object_url             => dato.object_url,
  :object_cache_url       => dato.object_cache_url,
  :thumbnail_url          => dato.thumbnail_url,
  :thumbnail_cache_url    => dato.thumbnail_cache_url,
  :location               => dato.location,
  :latitude               => dato.latitude,
  :longitude              => dato.longitude,
  :altitude               => dato.altitude,
  :object_created_at      => dato.object_created_at,
  :object_modified_at     => dato.object_modified_at,
  :created_at             => Time.now,
  :updated_at             => Time.now,
  :data_rating            => dato.data_rating,
  :vetted                 => dato.vetted,
  :visibility             => dato.visibility,
  :published              => true
  )                                                      
  
  #   2c) data_objects_table_of_contents
  if dato.text?
    old_dotoc = DataObjectsTableOfContent.find_by_data_object_id(dato.id)
    DataObjectsTableOfContent.gen(:data_object_id => new_dato.id,
                                  :toc_id => old_dotoc.toc_id)
  end
  #   2d) data_objects_taxa
  dato.taxa.each do |taxon|
    DataObjectsTaxon.gen(:data_object_id => new_dato.id, :taxon_id => taxon.id)
  end
  #   2e) if this is an image, remove the old image from top_images and insert the new image.
  if dato.image?
    TopImage.delete_all("data_object_id = #{dato.id}")
    TopImage.gen(:data_object_id => new_dato.id,
                 :hierarchy_entry_id => dato.hierarchy_entries.first.id)
    TopConceptImage.delete_all("data_object_id = #{dato.id}")
    TopConceptImage.gen(:data_object_id => new_dato.id,
                 :taxon_concept_id => dato.hierarchy_entries.first.taxon_concept_id)
  end
  # TODO - this could also handle tags, info items, and refs.
  # 3) unpublish old version 
  dato.published = false
  dato.save!
  return new_dato
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
  def add_user_submitted_text(options = {})
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
      dato.curate!(Vetted.trusted.id, nil, curator)
    end
    return dato
  end

  # Add a specific toc item to this TC's toc:
  def add_toc_item(toc_item, options = {})
    dato = DataObject.gen(:data_type => DataType.find_by_label('Text'))
    if options[:vetted] == false
      dato.vetted = Vetted.untrusted
    end
    DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => toc_item)
    dato.save!
    DataObjectsTaxon.gen(:data_object => dato, :taxon => taxa.first)
    FeedDataObject.gen(:taxon_concept => self, :data_object => dato, :data_type => dato.data_type)
    DataObjectsTaxonConcept.gen(:taxon_concept => self, :data_object => dato)
  end
  
  # Add a specific toc item to this TC's toc:
  def add_data_object(dato, options = {})
    if dato.data_type_id == DataType.text.id
      DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => dato.info_items[0].toc_item)
      dato.save!
    end
    DataObjectsTaxon.gen(:data_object => dato, :taxon => taxa.first)
    FeedDataObject.gen(:taxon_concept => self, :data_object => dato, :data_type => dato.data_type)
    DataObjectsTaxonConcept.gen(:taxon_concept => self, :data_object => dato)
  end

  # Add a synonym to this TC.
  def add_scientific_name_synonym(name_string, options = {})
    language  = Language.find_by_label("Scientific Name") # Note, this could be id 0
    preferred = false
    relation = SynonymRelation.find_by_label("synonym")
    name_obj = Name.find_by_clean_name(Name.prepare_clean_name name_string) || Name.gen(:canonical_form => canonical_form_object, :string => name_string, :italicized => name_string)
    generate_synonym(name_obj, Agent.first, :preferred => preferred, :language => language, :relation => relation)
  end

  # Only used in testing context, this returns the actual Name object for the canonical form for this TaxonConcept.
  # Note that, since the canonical form is what you see when browsing the site, this really comes from the Catalogue
  # of Life specifically, which may present a problem later.
  def canonical_form_object
    CanonicalForm.find(entry.name_object.canonical_form_id) # Yuck.  But true.
  end
end
