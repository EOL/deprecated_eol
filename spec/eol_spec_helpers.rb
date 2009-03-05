require 'lib/eol_data'

module EOL::Spec
  module Helpers

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

    # truncates all tables in all databases
    def truncate_all_tables options = { }
      # TODO don't do 1 execute for each table!  do 1 execute for each connection!  should be faster
      # puts "truncating all tables"
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

    # NOTE - I am not setting the mime type yet.  We never use it.
    # NOTE - There are no models for all the refs_* tables, so I'm ignoring them.
    # TODO - in several places, I call Model.all.rand.  This is less than efficient and needs optimization. I'm presently banking on
    # very small tables.  :)
    def build_data_object(type, desc, options = {})

      attributes = {:data_type   => DataType.find_by_label(type),
                    :description => desc,
                    :visibility  => Visibility.visible,
                    :vetted      => Vetted.trusted,
                    :license     => License.all.rand}

      he              = options.delete(:hierarchy_entry)
      name            = options.delete(:name)            || Name.gen
      scientific_name = options.delete(:scientific_name) || Factory.next(:scientific_name)
      taxon           = options.delete(:taxon)
      toc_item        = options.delete(:toc_item)
      taxon         ||= Taxon.gen(:name => name, :hierarchy_entry => he, :scientific_name => scientific_name)

      options[:object_cache_url] ||= Factory.next(:image) if type == 'Image'

      dato            = DataObject.gen(attributes.merge(options))

      DataObjectsTaxon.gen(:data_object => dato, :taxon => taxon)

      if type == 'Image'
        if dato.visibility == Visibility.visible and dato.vetted == Vetted.trusted
          TopImage.gen :data_object => dato, :hierarchy_entry => he
        else
          TopUnpublishedImage.gen :data_object => dato, :hierarchy_entry => he
        end
      elsif type == 'Text'
        DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => toc_item || TocItem.all.rand)
      end
      (rand(60) - 39).times { Comment.gen(:parent => dato, :user => User.all.rand) }
      return dato
    end

    def build_hierarchy_entry(depth, tc, name, options = {})
      he    = HierarchyEntry.gen(:hierarchy     => options[:hierarchy] || Hierarchy.default,
                                 :parent_id     => options[:parent_id] || 0,
                                 :depth         => depth,
                                 :rank_id       => depth + 1, # Cheating. As long as the order is sane, this works well.
                                 :taxon_concept => tc,
                                 :name          => name)
      HierarchiesContent.gen(:hierarchy_entry => he, :text => 1, :image => 1, :content_level => 4, :gbif_image => 1, :youtube => 1, :flash => 1)
      return he
    end

    # == Options:
    #
    # These all have intelligent(ish) default values, so just specify those values that you feel are really salient.
    #
    #   +attribution+:: String to be used in scientific name as attribution
    #   +canonical_form+:: String to use for canonical form (all names will reference this)
    #   +comments+:: Array of hashes.  Each hash can have a +:body+ and +:user+ key.
    #   +common_name+:: String to use for thre preferred common name
    #   +depth+:: Depth to apply to the attached hierarchy entry.  Don't supply this AND rank.
    #   +flash+:: Array of flash videos, each member is a hash for the video options.  The keys you will want are +:description+ and
    #             +:object_cache_url+.
    #   +images+:: Attay of hashes.  Each hash may have the following keys: +:description+, +:hierarchy_entry+, +:object_cache_url+,
    #              +:taxon+, +:vetted+, +:visibility+  ...These are the args used to call #build_data_object
    #   +italicized+:: String to use for preferred scientific name's italicized form.
    #   +iucn_status+:: String to use for IUCN description
    #   +map+:: A hash to build a map data object with. The keys you will want are +:description+ and +:object_cache_url+.
    #   +parent_hierarchy_entry_id+:: When building the associated HierarchyEntry, this id will be used for its parent.
    #   +rank+:: String form of the Rank you want this TC to be.  Default 'species'.
    #   +scientific_name+:: String to use for the preferred scientific name.
    #   +toc+:: An array of hashes.  Each hash may have a +:toc_item+ key and a +:description+ key.
    #   +youtube+:: Array of YouTube videos, each member is a hash for the video options.  The keys you will want are +:description+
    #               and +:object_cache_url+.
    def build_taxon_concept(options = {})
      attri = options[:attribution] || Factory.next(:attribution)
      common_name = options[:common_name] || Factory.next(:common_name)
      iucn_status = options[:iucn_status] || Factory.next(:iucn)
      canon       = options[:canonical_form] || Factory.next(:scientific_name)
      cform = CanonicalForm.find_by_string(canon) || CanonicalForm.gen(:string => canon)
      sname = Name.gen(:canonical_form => cform, :string => options[:scientific_name] || "#{canon} #{attri}".strip,
                       :italicized     => options[:italicized] || "<i>#{canon}</i> #{attri}".strip)
      cname = Name.gen(:canonical_form => cform, :string => common_name, :italicized => common_name)
      tc    = TaxonConcept.gen(:vetted => Vetted.trusted)
      # Note that this assumes the ranks are *in order* which is ONLY true with foundation loaded!
      depth = options[:depth] || Rank.find_by_label(options[:rank] || 'species').id - 1
      he    = build_hierarchy_entry(depth, tc, sname, :parent_id => options[:parent_hierarchy_entry_id])
      TaxonConceptName.gen(:preferred => true, :vern => false, :source_hierarchy_entry_id => he.id, :language => Language.scientific,
                           :name => sname, :taxon_concept => tc)
      TaxonConceptName.gen(:preferred => true, :vern => true, :source_hierarchy_entry_id => he.id, :language => Language.english,
                           :name => cname, :taxon_concept => tc)
      curator = Factory(:curator, :curator_hierarchy_entry => he)

      comments = options[:comments] || [{}, {}, {}] # Array with three empty hashes (default #), which we will populate with defaults:
      comments.each do |comment|
        comment[:body]  ||= "This is a witty comment on the #{canon} taxon concept. Any resemblance to comments real or imagined is" +
                            'coincidental.'
        comment[:user] ||= User.all.rand
        Comment.gen(:parent => tc, :parent_type => 'taxon_concept', :body => comment[:body], :user => comment[:user])
      end

      # TODO - add some alternate names, including at least one in another language.

      taxon = Taxon.gen(:name => sname, :hierarchy_entry => he, :scientific_name => canon)

      images = [] # This is used to build the RandomTaxon
      if options[:images].nil?
        options[:images] = []
        (rand(12)+3).times do
          options[:images] << {} # Defaults are handled below.
        end
        # So, every TC (which doesn't have a predefined list of images) will have each of the following, making testing easier:
        options[:images] << {:description => 'untrusted', :object_cache_url => Factory.next(:image), :vetted => Vetted.untrusted}
        options[:images] << {:description => 'unknown',   :object_cache_url => Factory.next(:image), :vetted => Vetted.unknown}
        options[:images] << {:description => 'invisible', :object_cache_url => Factory.next(:image), :visibility => Visibility.invisible}
        options[:images] << {:description => 'preview', :object_cache_url => Factory.next(:image), :visibility => Visibility.preview}
        options[:images] << {:description => 'invisible, unknown', 
                             :object_cache_url => Factory.next(:image), :visibility => Visibility.invisible, :vetted => Vetted.unknown}
        options[:images] << {:description => 'invisible, untrusted', 
                             :object_cache_url => Factory.next(:image), :visibility => Visibility.invisible, :vetted => Vetted.untrusted}
        options[:images] << {:description => 'preview, unknown', 
                             :object_cache_url => Factory.next(:image), :visibility => Visibility.preview, :vetted => Vetted.unknown}
        options[:images] << {:description => 'inappropriate', 
                             :object_cache_url => Factory.next(:image), :visibility => Visibility.inappropriate}
      end
      options[:images].each do |img|
        description             = img.delete(:description) || Faker::Lorem.sentence
        img[:taxon]           ||= taxon
        img[:hierarchy_entry] ||= he
        images << build_data_object('Image', description, img)
      end
      
      # TODO - Does an IUCN entry *really* need its own taxon?  I am surprised by this (it seems duplicated):
      iucn_taxon = Taxon.gen(:name => sname, :hierarchy_entry => he, :scientific_name => canon)
      iucn = build_data_object('IUCN', iucn_status, :taxon => iucn_taxon)
      HarvestEventsTaxon.gen(:taxon => iucn_taxon, :harvest_event => iucn_harvest_event)

      flash_options = options[:flash] || [{}] # Array with one empty hash, which we will populate with defaults:
      flash_options.each do |flash_opt|
        flash_opt[:description]      ||= Faker::Lorem.sentence
        flash_opt[:object_cache_url] ||= Factory.next(:flash)
        build_data_object('Flash', flash_opt[:description], :taxon => taxon, :object_cache_url => flash_opt[:object_cache_url])
      end

      youtube_options = options[:youtube] || [{}] # Array with one empty hash, which we will populate with defaults:
      youtube_options.each do |youtube_opt|
        youtube_opt[:description]      ||= Faker::Lorem.sentence
        youtube_opt[:object_cache_url] ||= Factory.next(:youtube)
        build_data_object('YouTube', youtube_opt[:description], :taxon => taxon, :object_cache_url => youtube_opt[:object_cache_url])
      end

      map_options = options[:map] || {} # Empty hash so that we can have default values for each key:
      map_options[:description]      ||= Faker::Lorem.sentence
      map_options[:object_cache_url] ||= Factory.next(:map)
      map     = build_data_object('GBIF Image', map_options[:description],  :taxon => taxon,
                                  :object_cache_url => map_options[:object_cache_url])

      if options[:toc].nil?
        options[:toc] = [{:toc_item => TocItem.overview, :description => "This is an overview of the <b>#{canon}</b> hierarchy entry."}]
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
      # TODO - Creating other TOC items (common names, BHL, synonyms, etc) would be nice 

      RandomTaxon.gen(:language => Language.english, :data_object => images.last, :name_id => sname.id,
                      :image_url => images.last.object_cache_url, :name => sname.italicized, :content_level => 4, :taxon_concept => tc,
                      :common_name_en => cname.string, :thumb_url => images.first.object_cache_url) # not sure thumb_url is right.
      return tc
    end

    def iucn_harvest_event
      # Why am I using cache?  ...Because I know we clear it when we nuke the DB...
      Rails.cache.fetch(:iucn_harvest_event) do
        HarvestEvent.find_by_resource_id(Resource.iucn.id) 
      end
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
