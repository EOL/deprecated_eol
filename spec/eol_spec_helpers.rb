require 'eol_data'
require 'nokogiri'

# TODO: Problem running eol:db:populate RAILS_ENV=development HTTP requests for SOLR were being prevented by WebMock,
# but WebMock is not loaded for development environment!? Presumably scenarios use this file which is why
# WebMock was getting loaded. So may we should move the require and stub request to a separate helper file?
# for now this config allows localhost requests.
require 'webmock/rspec'
WebMock.allow_net_connect!

module EOL
  module RSpec
    module Helpers

      def login_as(user, options = {})
        if user.is_a? User # let us pass a newly created user (with an entered_password)
          options.reverse_merge!(:username => user.username, :password => user.entered_password)
        elsif user.is_a? Hash
          options = options.merge(user)
        end
        visit logout_path
        visit login_path
        fill_in "session_username_or_email", :with => options[:username]
        fill_in "session_password", :with => options[:password] || 'test password'
        check("remember_me") if options[:remember_me] && options[:remember_me].to_i != 0
        click_button I18n.t("helpers.submit.session.create")
        page
      end

      # returns a connection for each of our databases, eg: 1 for Data, 1 for Logging ...
      # TODO - this is not a nice abstract way of getting the list of connections we have.  We should generalize.
      def all_connections
        begin
          EOL::DB.all_connections
        rescue => e
          load 'lib/eol_data.rb' # Weird that this happens (in the middle of specs, no less), but it does.
          EOL::DB.all_connections
        end
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

      def recreate_solr_indexes
        solr = SolrAPI.new($SOLR_SERVER, $SOLR_TAXON_CONCEPTS_CORE)
        solr.delete_all_documents
        solr.build_indexes
      end

      # truncates all tables in all databases
      def truncate_all_tables(options = {})
        options[:skip_empty_tables] = true if options[:skip_empty_tables].nil?
        options[:verbose] ||= false
        all_connections.uniq.each do |conn|
          count = 0
          conn.tables.each do |table|
            next if table == 'schema_migrations'
            count += 1
            if conn.respond_to? :with_master
              conn.with_master do
                truncate_table(conn, table, options[:skip_empty_tables])
              end
            else
              truncate_table(conn, table, options[:skip_empty_tables])
            end
          end
          puts "-- Truncated #{count} tables in #{conn.instance_eval { @config[:database] }}." if options[:verbose]
        end
        Rails.cache.clear if Rails.cache
      end

      def truncate_table(conn, table, skip_if_empty)
        # run_command = skip_if_empty ? conn.execute("SELECT 1 FROM #{table} LIMIT 1").num_rows > 0 : true
        # conn.execute "TRUNCATE TABLE `#{table}`" if run_command
        conn.execute "TRUNCATE TABLE `#{table}`"
      end

      def drop_all_virtuoso_graphs
        # print "dropping all virtuoso graphs ... "
        # NOTE - for some reason (?) this keeps throwing "invalid port" errors.
        EOL::Sparql.connection.query("SELECT DISTINCT ?graph WHERE { GRAPH ?graph { ?s ?p ?o } }").each do |result|
          graph_name = result[:graph].to_s
          if graph_name =~ /^http:\/\/eol\.org\//
            EOL::Sparql.connection.delete_graph(graph_name)
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
        # TODO - Create two AgentsHierarchyEntry(ies); you want "Source Database" and "Compiler" as partner roles
        return he
      end

      def build_taxon_concept(options = {})
        tc_builder = EOL::TaxonConceptBuilder.new(options)
        return tc_builder.tc
      end

      # A dumbed-down version of #build_curator
      def gen_curator(options = {})
        options = {
          curator_level:    options[:curator_level] || CuratorLevel.full,
          curator_approved: true,
          curator_scope:    'scope',
          credentials:      'Curator'
        }.merge(options)
        curator = User.gen(options)
      end

      # Curators are tricky... not just a plain model, but require some activity before they are "active":
      # The first argument is the TaxonConcept or HierarchyEntry to associate the curator to; the second argument is
      # the options hash to use when building the User model.
      def build_curator(entry, options = {})
        curator_level = options[:level].nil? ? :full : options[:level]
        options.delete :level
        entry ||= FactoryGirl.create(:hierarchy_entry)
        tc = nil # scope
        if entry.class == TaxonConcept
          tc    = entry
          entry = tc.entry
        end
        tc ||= entry.taxon_concept
        options = {
          :curator_approved        => true,
          :curator_scope           => 'scope',
          :credentials             => 'Curator'
        }.merge(options)

        # These two do "extra work", so I didn't want to use the merge on these (because they would be calculated even
        # if not used:
        options[:curator_verdict_by] ||= FactoryGirl.create(:user)
        options[:curator_verdict_at] ||= 48.hours.ago

        curator = User.gen(options)
        curator.grant_curator(curator_level)

        cot = ChangeableObjectType.gen_if_not_exists(:ch_object_type => 'taxon_concept')
        CuratorActivityLog.gen(:user => curator, :taxon_concept => tc, :changeable_object_type => cot,
                               :target_id => tc.id)

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
        HarvestEventsHierarchyEntry.gen(:hierarchy_entry => iucn_he, :harvest_event => options[:event])
        build_data_object('IUCN', status, :hierarchy_entry => iucn_he, :published => 1)
      end

      def find_or_build_hierarchy(label)
        Hierarchy.find_by_label(label) || Hierarchy.gen(:label => label)
      end

      def find_or_build_resource(title, options = {})
        first_try = Resource.find_by_title(title)
        return first_try unless first_try.nil?
        options[:content_partner] ||= ContentPartner.gen(:full_name => 'Test content partner')
        resource = Resource.gen(:title => title, :content_partner => options[:content_partner])
        return resource
      end

      def find_or_build_harvest_event(resource)
        HarvestEvent.find_by_resource_id(resource.id) || HarvestEvent.gen(:resource => resource)
      end

      def iucn_hierarchy
        find_or_build_hierarchy('IUCN')
      end

      def default_harvest_event
        find_or_build_harvest_event(find_or_build_resource('Test Framework Import', :content_partner => ContentPartner.last))
      end

      def gbif_harvest_event
        find_or_build_harvest_event(find_or_build_resource('Initial GBIF Import'))
      end

      def iucn_harvest_event
        find_or_build_harvest_event(Resource.iucn)
      end

      def load_foundation_cache
        truncate_all_tables
        load_scenario_with_caching(:foundation)
      end

      def load_scenario_with_caching(name)
        loader = EOL::ScenarioLoader.new(name, all_connections)
        # TODO - this may want to check if it NEEDS loading, here, and then truncate the tables before proceeding, if it
        # does.
        loader.load_with_caching
      end

      def oauth_request_data(provider, oauth_protocol = 1)
        case oauth_protocol
        when 1
          params_data = { :oauth_provider => provider.to_s,
                          :oauth_token => 'key',
                          :oauth_verifier => 'verifier' }
          session_data = { "#{provider}_request_token_token" => 'key',
                           "#{provider}_request_token_secret" => 'secret' }
        when 2
          params_data = { :oauth_provider => provider.to_s,
                          :code => 'code' }
          session_data = nil
        end
        return params_data, session_data
      end

      # Fakes responses for external HTTP requests. Requires WebMock gem.
      def stub_oauth_requests
        # Facebook
        stub_request(:post, "https://graph.facebook.com/oauth/access_token").
                    to_return(:status => 200,
                              :headers => {'Content-Type' => 'application/x-www-form-urlencoded'},
                              :body => "access_token=key")
        stub_request(:get, "https://graph.facebook.com/me?access_token=key").
                    to_return(:status => 200,
                              :headers => {'Content-Type' => 'text/json'},
                              :body => '{ "id": "facebookuserguid",
                                          "email": "facebook@example.com",
                                          "last_name": "FacebookFamily",
                                          "first_name": "FacebookGiven" }')
        # Google
        stub_request(:post, "https://accounts.google.com/o/oauth2/token").
                    to_return(:status => 200,
                              :headers => {'Content-Type' => 'application/x-www-form-urlencoded'},
                              :body => "access_token=key")
        stub_request(:get, "https://www.googleapis.com/oauth2/v1/userinfo?access_token=key").
                    to_return(:status => 200,
                              :headers => {'Content-Type' => 'text/json'},
                              :body => '{ "id": "googleuserguid",
                                          "email": "google@example.com",
                                          "last_name": "GoogleFamily",
                                          "first_name": "GoogleGiven" }')
        # Twitter
        stub_request(:post, "http://api.twitter.com/oauth/request_token").
                    to_return(:status => 200,
                              :headers => {},
                              :body => "oauth_token=key&oauth_token_secret=secret")
        stub_request(:post, "http://api.twitter.com/oauth/access_token").
                    to_return(:status => 200,
                              :headers => {},
                              :body => "oauth_token=key&oauth_token_secret=secret")
        stub_request(:get, "https://api.twitter.com/1.1/account/verify_credentials.json").
                    to_return(:status => 200,
                              :headers => {},
                              :body => '{ "id": "twitteruserguid",
                                          "name": "TwitterFamily TwitterGiven" }')

        # Yahoo!
        stub_request(:post, "https://api.login.yahoo.com/oauth/v2/get_request_token").
                    to_return(:status => 200,
                              :headers => {},
                              :body => "oauth_token=key&oauth_token_secret=secret&xoauth_yahoo_guid=yahoouserguid")
        stub_request(:post, "https://api.login.yahoo.com/oauth/v2/get_token").
                    to_return(:status => 200,
                              :headers => {},
                              :body => "oauth_token=key&oauth_token_secret=secret&xoauth_yahoo_guid=yahoouserguid")
        stub_request(:get, "http://social.yahooapis.com/v1/user/yahoouserguid/profile?format=json").
                    to_return(:status => 200,
                              :headers => {},
                              :body => '{ "profile": { "guid": "yahoouserguid",
                                                       "familyName": "YahooFamily",
                                                       "givenName": "YahooGiven" }}')
        # Faked OAuth1 provider requests and responses
        stub_request(:post, "http://fake.oauth1.provider/example/access_token_denied").
                     to_return(:status => 401, :headers => {}, :body => "")
        stub_request(:any, "http://fake.oauth1.provider/example/request_token").
                    to_return(:status => 200,
                              :headers => {},
                              :body => "oauth_token=key&oauth_token_secret=secret")
        stub_request(:post, "http://fake.oauth1.provider/example/access_token").
                    to_return(:status => 200,
                              :headers => {},
                              :body => "oauth_token=key&oauth_token_secret=secret")
        # Faked OAuth2 provider requests and responses
        stub_request(:post, "https://fake.oauth2.provider/example/access_token").
                    to_return(:status => 200,
                              :headers => {'Content-Type' => 'application/x-www-form-urlencoded'},
                              :body => "access_token=key")
      end

      def get_as_xml(path)
        visit(path)
        Nokogiri.XML(source)
      end

      def get_as_json(path)
        visit(path)
        JSON.parse(source)
      end

      def check_api_key(url, user)
        visit(url)
        log = ApiLog.last
        url.split(/[\?&]/).each do |url_part|
          log.request_uri.should match(url_part)
        end
        log.key.should_not be_nil
        log.key.should == user.api_key
        log.user_id.should == user.id
      end
    end
  end
end

def DataObject.build_reharvested_dato(dato)
  new_dato = self.gen(
  :guid                   => dato.guid,
  :identifier             => dato.identifier,
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
  :published              => true
  )

  #   2c) data_objects_table_of_contents
  if dato.text?
    old_dotoc = DataObjectsTableOfContent.find_by_data_object_id(dato.id)
    DataObjectsTableOfContent.gen(:data_object_id => new_dato.id,
                                  :toc_id => old_dotoc.toc_id)
  end
  #   2d) data_objects_hierarchy_entries
  dato.hierarchy_entries.each do |he|
    DataObjectsHierarchyEntry.gen(:data_object_id => new_dato.id, :hierarchy_entry_id => he.id)
    DataObjectsTaxonConcept.gen(:taxon_concept => he.taxon_concept, :data_object => new_dato)
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
    type = RefIdentifierType.find_by_label(type) || RefIdentifierType.gen_if_not_exists(:label => type)
    # TODO - I can take off the :ref => self, right?  For now, being safe.
    self.ref_identifiers << RefIdentifier.gen_if_not_exists(:ref_identifier_type => type, :identifier => identifier, :ref => self)
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
  #     The license the text was submitted as.  Defaults to Public Domain, if you choose another one make sure you add Rights Holder.
  #   +rights_holder+:
  #     Owner of rights for the text. Must NOT be blank if License is NOT Public Domain. Must be blank if License is Public Domain.
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
    options = {:description       => 'some random text',
               :user              => User.last,
               :toc_item          => TocItem.overview,
               :license           => License.public_domain,
               :rights_holder     => '',
               :language          => Language.english,
               :vetted            => false
              }.merge(options)
    dato = DataObject.create_user_text(
      { :object_title => options[:title],
        :license_id => options[:license].id,
        :language_id => options[:language].id,
        :description => options[:description],
        :rights_holder     => options[:rights_holder]
      },
      :toc_id => [options[:toc_item].id],
      :user => options[:user],
      :taxon_concept => self
    )
    if options[:vetted]
      curator = User.find(self.curators.first) # Curators array doesn't return "full" user objects...
      curator ||= User.first
      dato.curate(curator, :vetted_id => Vetted.trusted.id)
    end
    return dato
  end

  # Add a specific toc item to this TC's toc:
  def add_toc_item(toc_item, options = {})
    dato = DataObject.gen(:data_type => DataType.find_by_translated(:label, 'Text'))
    if options[:vetted] == false
      dato.vetted = Vetted.untrusted
    end
    DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => toc_item)
    dato.save!
    DataObjectsHierarchyEntry.gen(:data_object => dato, :hierarchy_entry => hierarchy_entries.first)
    DataObjectsTaxonConcept.gen(:taxon_concept => self, :data_object => dato)
  end

  # Add a specific toc item to this TC's toc:
  def add_data_object(dato, options = {})
    if dato.data_type_id == DataType.text.id
      DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => dato.info_items[0].toc_item)
      dato.save!
    end
    DataObjectsHierarchyEntry.gen(:data_object => dato, :hierarchy_entry => hierarchy_entries.first)
    DataObjectsTaxonConcept.gen(:taxon_concept => self, :data_object => dato)
  end

  # Add a synonym to this TC.
  def add_scientific_name_synonym(name_string, options = {})
    language  = Language.scientific # Note, this could be id 0
    preferred = false
    relation = SynonymRelation.find_by_translated(:label, "synonym")
    name_obj = Name.find_by_clean_name(Name.prepare_clean_name name_string) || Name.gen(:canonical_form => canonical_form_object, :string => name_string, :italicized => name_string)
    Synonym.generate_from_name(name_obj, :agent => Agent.first, :preferred => preferred, :language => language,
                               :entry => entry, :relation => relation)
  end

  # Only used in testing context, this returns the actual Name object for the canonical form for this TaxonConcept.
  # Note that, since the canonical form is what you see when browsing the site, this really comes from the Catalogue
  # of Life specifically, which may present a problem later.
  def canonical_form_object
    CanonicalForm.find(entry.name.canonical_form_id) # Yuck.  But true.
  end

end

DataObject.class_eval do
  def add_ref(full_reference, published, visibility)
    self.refs << ref = Ref.gen(:full_reference => full_reference, :published => published, :visibility => visibility)
    ref
  end
end

