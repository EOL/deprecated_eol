require 'lib/eol_data'

module EOL::Spec
  module Helpers

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

    def login_as options = { }
      if options.is_a?User # let us pass a newly created user (with an entered_password)
        options = { :username => options.username, :password => options.entered_password }
      end
      request('/account/authenticate', :params => { 
          'user[username]' => options[:username], 
          'user[password]' => options[:password] })
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
      scientific_name = options.delete(:scientific_name) || Faker::Eol.scientific_name
      taxon           = options.delete(:taxon)
      toc_item        = options.delete(:toc_item)
      taxon         ||= Taxon.gen(:name => name, :hierarchy_entry => he, :scientific_name => scientific_name)

      options[:object_cache_url] ||= Faker::Eol.image if type == 'Image'

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

    def build_hierarchy_entry(parent, depth, tc, name, options = {})
      he    = HierarchyEntry.gen(:hierarchy     => options[:hierarchy] || Hierarchy.default,
                                 :parent_id     => options[:parent_id] || 0,
                                 :depth         => depth,
                                 :rank_id       => depth + 1, # Cheating. As long as the order is sane, this works well.
                                 :taxon_concept => tc,
                                 :name          => name)
      HierarchiesContent.gen(:hierarchy_entry => he, :text => 1, :image => 1, :content_level => 4, :gbif_image => 1, :youtube => 1, :flash => 1)
      return he
    end

    def build_taxon_concept(parent, depth, options = {})
      attri = options[:attribution] || Faker::Eol.attribution
      common_name = options[:common_name] || Faker::Eol.common_name
      cform = CanonicalForm.gen(:string => options[:canonical_form] || Faker::Eol.scientific_name)
      sname = Name.gen(:canonical_form => cform, :string => "#{cform.string} #{attri}".strip,
                       :italicized     => "<i>#{cform.string}</i> #{attri}".strip)
      cname = Name.gen(:canonical_form => cform, :string => common_name, :italicized => common_name)
      tc    = TaxonConcept.gen(:vetted => Vetted.trusted)
      he    = build_hierarchy_entry(parent, depth, tc, sname)
      TaxonConceptName.gen(:preferred => true, :vern => false, :source_hierarchy_entry_id => he.id, :language => Language.scientific,
                           :name => sname, :taxon_concept => tc)
      TaxonConceptName.gen(:preferred => true, :vern => true, :source_hierarchy_entry_id => he.id, :language => Language.english,
                           :name => cname, :taxon_concept => tc)
      curator = Factory(:curator, :curator_hierarchy_entry => he)
      (rand(60) - 39).times { Comment.gen(:parent => tc, :parent_type => 'taxon_concept', :user => User.all.rand) }
      # TODO - add some alternate names, including at least one in another language.

      taxon = Taxon.gen(:name => sname, :hierarchy_entry => he, :scientific_name => cform.string)
      images = []
      (rand(12)+3).times do
        images << build_data_object('Image', Faker::Lorem.sentence, :taxon => taxon, :hierarchy_entry => he)
      end
      # So, every HE will have each of the following, making testing easier:
      images << build_data_object('Image', 'untrusted', taxon, he, :object_cache_url => Faker::Eol.image,
                           :vetted => Vetted.untrusted)
      images << build_data_object('Image', 'unknown', taxon, he, :object_cache_url => Faker::Eol.image,
                           :vetted => Vetted.unknown)
      images << build_data_object('Image', 'invisible', taxon, he, :object_cache_url => Faker::Eol.image,
                           :visibility => Visibility.invisible)
      images << build_data_object('Image', 'invisible, unknown', taxon, he, :object_cache_url => Faker::Eol.image,
                           :visibility => Visibility.invisible, :vetted => Vetted.unknown)
      images << build_data_object('Image', 'invisible, untrusted', taxon, he, :object_cache_url => Faker::Eol.image,
                           :visibility => Visibility.invisible, :vetted => Vetted.untrusted)
      images << build_data_object('Image', 'preview', taxon, he, :object_cache_url => Faker::Eol.image,
                           :visibility => Visibility.preview)
      images << build_data_object('Image', 'preview, unknown', taxon, he, :object_cache_url => Faker::Eol.image,
                           :visibility => Visibility.preview, :vetted => Vetted.unknown)
      images << build_data_object('Image', 'inappropriate', taxon, he, :object_cache_url => Faker::Eol.image,
                           :visibility => Visibility.inappropriate)
      
      # TODO - Does an IUCN entry *really* need its own taxon?  I am surprised by this (it seems dupicated):
      iucn_taxon = Taxon.gen(:name => sname, :hierarchy_entry => he, :scientific_name => cform.string)
      iucn = build_data_object('IUCN', Faker::Eol.iucn, iucn_taxon)
      # TODO - this is a TOTAL hack, but this is currently hard-coded and needs to be fixed:
      HarvestEventsTaxon.gen(:taxon => iucn_taxon, :harvest_event => iucn_harvest_event)

      video   = build_data_object('Flash',      Faker::Lorem.sentence,  taxon, nil, :object_cache_url => Faker::Eol.flash)
      youtube = build_data_object('YouTube',    Faker::Lorem.paragraph, taxon, nil, :object_cache_url => Faker::Eol.youtube)
      map     = build_data_object('GBIF Image', Faker::Lorem.sentence,  taxon, nil, :object_cache_url => Faker::Eol.map)

      overview = build_data_object('Text', "This is an overview of the <b>#{cform.string}</b> hierarchy entry.", taxon,
                                   :toc_item => TocItem.overview)
      # Add more toc items:
      (rand(4)+1).times do
        dato = build_data_object('Text', Faker::Lorem.paragraph, taxon)
      end
      # TODO - Creating other TOC items (common names, BHL, synonyms, etc) would be nice 

      RandomTaxon.gen(:language => Language.english, :data_object => images.last, :name_id => sname.id,
                      :image_url => images.last.object_cache_url, :name => sname.italicized, :content_level => 4, :taxon_concept => tc,
                      :common_name_en => cname.string, :thumb_url => images.first.object_cache_url) # not sure thumb_url is right.
    end

    def iucn_harvest_event
      @@iucn_he ||= HarvestEvent.gen(:resource_id => Resource.iucn.id)
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
