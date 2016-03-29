class TaxonConceptBuilder

  attr_reader :tc

  include EOL::Builders # Allows us to build data objects, users, and the like...

  # == Options:
  #
  # These all have intelligent(ish) default values, so just specify those values that you feel are really salient. Note that a TC will
  # NOT have a map or an IUCN status unless you specify options that create them.
  #
  #   +attribution+::
  #     String to be used in scientific name as attribution
  #   +bhl+::
  #     Example: [{:publication => 'Foobar', :page => 23}, {:publication => 'Bazboozer', :page => 78}]
  #   +canonical_form+::
  #     String to use for canonical form (all names will reference this)
  #   +comments+::
  #     Array of hashes.  Each hash can have a +:body+ and +:user+ key.
  #   +common_names+::
  #     Array of strings to use for the common names.
  #   +depth+::
  #     Depth to apply to the attached hierarchy entry.  Don't supply this AND rank.
  #   +event+::
  #     HarvestEvent to associate the taxon to.
  #   +flash+::
  #     Array of flash videos, each member is a hash for the video options.  The keys you will want are
  #     +:description+ and +:object_cache_url+.
  #   +id+::
  #     Forces the ID of the TaxonConcept to be what you specify, useful for exemplars.
  #   +vetted+::
  #     Modifies taxon concept vetted status. Can be 'trusted', 'untrusted', 'unknown', default is 'trusted'
  #   +images+::
  #     Array of hashes.  Each hash may have the following keys: +:description+, +:hierarchy_entry+,
  #     +:object_cache_url+, +:taxon+, +:vetted+, +:visibility+ ...These are the args used to call #build_data_object
  #     ALSO, the :images parameter may be set to :testing, which will create one image with lots of comments, as
  #     well as one image of each vetted/visibility status, which is... uhhh... good for testing?
  #     DEFAULT value is simply two images.
  #   +italicized+::
  #     String to use for preferred scientific name's italicized form.
  #   +iucn_status+::
  #     String to use for IUCN description, OR just set to true if you want a random IUCN status instead.
  #   +biomedical_terms+::
  #     Set to true (default is false) if you want the TOC to include an entry for Medical Concepts.  Note that
  #     this is the "LigerCat Tag Cloud" entry.
  #   +parent_hierarchy_entry_id+::
  #     When building the associated HierarchyEntry, this id will be used for its parent.
  #   +rank+::
  #     String form of the Rank you want this TC to be.  Default 'species'.
  #   +scientific_name+::
  #     String to use for the preferred scientific name.  The first in the list will be "preferred"
  #   +sounds+::
  #     Array of audio files, each member is a hash containing options for sound object. The relevant keys are
  #     +:description+ and +:object_cache_url+.
  #   +toc+::
  #     An array of hashes.  Each hash may have a +:toc_item+ key and a +:description+ key. Note that there are
  #     some toc entries that you CANNOT affect here, like common_names, bhl, or biomedical_terms, since they are
  #     "special" and require more work.  See the options of those names for more information.
  #   +youtube+::
  #     Array of YouTube videos, each member is a hash for the video options.  The keys you will want are
  #     +:description+ and +:object_cache_url+.
  # TODO - Create a harvest event and a resource (status should be published) (and the resource needs a hierarchy, which we use for
  # the HEs)
  # TODO - Normalize names ... when harvesting is done, this is done on-the-fly, so we should do it here.
  # NOTE: when we denormalize the taxon_concept_names table, we should be looking at Synonyms as well as Names.
  def self.build(options)
    builder = TaxonConceptBuilder.new(options)
    builder.tc
  end

  def initialize(options)
    @debugging = false
    puts "** Enter: initialize" if @debugging
    set_default_options(options)
    build
  end

private

  def build
    puts "** Enter: build" if @debugging
    gen_taxon_concept
    set_depth
    gen_canonical_name
    gen_he
    gen_other_names unless @common_names.blank? # to add common names: should send them in params
    add_scientific_name unless @sname.nil? # to add scientific name: should set sname in params
    add_curator
    add_comments unless @comments.blank? # to create light taxon concept
    add_images unless   @images.blank? # to create light taxon concept
    add_videos unless   @flash.blank? || @youtube.blank? # to create light taxon concept
    add_sounds unless   @sounds.blank? # to create light taxon concept
    add_toc unless   @toc.blank? # to create light taxon concept
    add_iucn unless @iucn_status.nil? # to add iucn: should set iucn_status in params
    gen_bhl unless @bhl.blank? # to create light taxon concept
    gen_biomedical_terms unless @biomedical_terms.nil? # to add biomedical terms: should set them in params

    #denormalized tables
    gen_random_hierarchy_image unless @image_objs.blank? or @sname.blank? # to create light taxon concept
    add_data_objects_taxon_concepts
  end

  # There isn't much involved with the actual TaxonConcept, in terms of the database and/or generation of the model
  # itself.  It's basically just an ID which is either published/vetted or not.
  #
  # That said, sometimes, we want a particular ID, so this method includes a little hacking to get that done.
  def gen_taxon_concept
    puts "** Enter: gen_taxon_concept" if @debugging
    vetted = Vetted.send(@vetted.to_sym)
    # TODO - in the future, we may want to be able to muck with the vetted *and* the published fields...
    # HACK!  We need to force the IDs of one of the TaxonConcepts, so that the exmplar array isn't empty.  I
    # hate to do it this way, but, alas, this is how it currently works:
    if @id
      @tc = TaxonConcept.find(@id) rescue nil
      if @tc.nil?
        @tc = TaxonConcept.gen(:vetted => vetted)
        TaxonConcept.connection.execute("UPDATE taxon_concepts SET id = #{@id} WHERE id = #{@tc.id}")
        @tc = TaxonConcept.find(@id)
      end
      @tc = @tc.first if @tc.class == Array  # TODO - why in the WORLD is this an array?  ...but it is...
    else
      @tc = TaxonConcept.gen(:vetted => vetted)
      @id = @tc.id
    end
  end

  def set_depth
    # Note that this assumes the ranks are *in order* which is ONLY true with foundation loaded!
    #load rank table only not all foundation
    @depth = @depth || Rank.find_by_translated(:label, @rank || 'species').id - 1 # This is an assumption...
  end

  def gen_he
    if @he
      @he.update_column(:taxon_concept_id, @tc.id)
    else
      @he ||= build_entry_in_hierarchy(:parent_id => @parent_hierarchy_entry_id)
    end
    HarvestEventsHierarchyEntry.gen(:hierarchy_entry => @he, :harvest_event => @event)
    # TODO - Create some references here ... just a string and an associated identifier (like a URL)
  end

  # TODO - add some alternate names, including at least one in another language.
  # TODO - create alternate scientific names... just make sure the relation makes sense and the language_id is
  # either 0 or Language.scientific.
  def gen_canonical_name
    puts "** Enter: gen_canonical_name" if @debugging
    @cform = CanonicalForm.find_by_string(@canon) || CanonicalForm.gen(:string => @canon)
    @rcform = CanonicalForm.find_by_string(@ranked_canonical_form) || CanonicalForm.gen(:string => @ranked_canonical_form)
    @sname = Name.find_by_string(@complete) || Name.gen(:canonical_form => @cform, :ranked_canonical_form => @rcform,
      :string => @complete, :italicized => @italicized || "<i>#{@canon}</i> #{@attri}".strip)
  end

  # TODO - add some alternate names, including at least one in another language.
  # TODO - create alternate scientific names... just make sure the relation makes sense and the language_id is
  # either 0 or Language.scientific.
  # Note that the last common name (if there is more than one common name) will be entered with the French language.
  def gen_other_names
    puts "** Enter: gen_other_names" if @debugging
    @common_names.each_with_index do |common_name, count|
      language = (count != 0 && count == @common_names.size) ? Language.find_by_translated(:label, "French") : Language.english
      @tc.add_common_name_synonym(common_name, :agent => Agent.col, :language => language)
    end
  end

  def add_scientific_name
    @tc.add_scientific_name_synonym(@sname.string, Agent.col)
  end

  def add_curator
    puts "** Enter: add_curator" if @debugging
    @curator = build_curator(@he)
  end

  def add_comments
    puts "** Enter: add_comments" if @debugging
    # Array with three empty hashes (default #), which we will populate with defaults:
    @comments.each do |comment|
      comment[:body]  ||= "This is a witty comment on the #{@canon} taxon concept. Any resemblance to comments real " +
                          'or imagined is coincidental.'
      comment[:user] ||= User.count == 0 ? User.gen : User.all.sample
      Comment.gen(:parent => @tc, :parent_type => 'TaxonConcept', :body => comment[:body], :user => comment[:user])
    end
  end

  def add_images
    puts "** Enter: add_images" if @debugging
    @images.each do |img|
      description   = img.delete(:description) || Faker::Lorem.sentence
      img[:hierarchy_entry] ||= @he
      @image_objs << build_object_in_event('Image', description, img)
    end
  end

  def add_videos
    puts "** Enter: add_videos" if @debugging
    @flash.each do |flash_opt|
      desc = flash_opt.delete(:description) || Faker::Lorem.sentence
      flash_opt[:object_cache_url] ||= FactoryGirl.generate(:flash)
      flash_opt[:hierarchy_entry] ||= @he
      build_object_in_event('Flash', desc, flash_opt)
    end

    @youtube.each do |youtube_opt|
      desc = youtube_opt.delete(:description) || Faker::Lorem.sentence
      youtube_opt[:object_cache_url] ||= FactoryGirl.generate(:youtube)
      youtube_opt[:hierarchy_entry] ||= @he
      build_object_in_event('YouTube', desc, youtube_opt)
    end
  end

  def add_sounds
    puts "** Enter: add_sounds" if @debugging
    @sounds.each do |sound_opt|
      desc   = sound_opt.delete(:description) || Faker::Lorem.sentence
      sound_opt[:object_cache_url] ||= FactoryGirl.generate(:sound)
      sound_opt[:hierarchy_entry] ||= @he
      build_object_in_event('Sound', desc, sound_opt)
    end
  end

  def add_iucn
    puts "** Enter: add_iucn" if @debugging
    iucn_status = @iucn_status == true ? FactoryGirl.generate(:iucn) : @iucn_status
    build_iucn_entry(@tc, iucn_status, :depth => @depth)
  end

  def add_toc
    puts "** Enter: add_toc" if @debugging
    @toc.each do |toc_item|
      toc_item[:toc_item]    ||= TocItem.all.sample
      toc_item[:description] ||= Faker::Lorem.paragraph
      toc_item[:vetted] ||= Vetted.trusted
      toc_item[:license] ||= License.cc
      toc_item[:rights_holder] ||= 'Someone'
      toc_item[:data_rating] ||= 2.5
      toc_item[:language] ||= Language.english
      toc_item[:language] = nil if toc_item.has_key?(:language_id)
      toc_item[:language_id] ||= toc_item[:language].id
      build_object_in_event('Text', toc_item[:description], :hierarchy_entry => @he,
                            :toc_item => toc_item[:toc_item], :vetted => toc_item[:vetted],
                            :license => toc_item[:license], :rights_holder => toc_item[:rights_holder],
                            :data_rating => toc_item[:data_rating], :language_id => toc_item[:language_id])
    end
    # We're missing the info items.  Technically, the toc_item would be referenced by looking at the info items (creating any we're
    # missing).  TODO - we should build the info item first and let the toc_item resolve from that.
    # TODO Outlinks: create a Collection related to any agent, and then give it a mapping with a foreign_key that links to some external
    # site. (optionally, you could use collection.uri and replace the FOREIGN_KEY bit)
  end

  # TODO - This is one of the slower methods.
  def gen_bhl
    puts "** Enter: gen_bhl" if @debugging
    @bhl.each do |bhl|
      publication = nil # scope
      if bhl[:publication].nil?
        publication = default_publication
      else
        publication = PublicationTitle.find_by_title(bhl[:publication])
        publication ||= PublicationTitle.gen(:title => bhl[:publication])
      end
      page = bhl[:page].to_i || (rand(400) + 1).to_i
      ti   = TitleItem.gen(:publication_title => publication)
      ip   = ItemPage.gen(:title_item => ti)
      pn   = PageName.gen(:item_page => ip, :name => @sname)
    end
  end

  def default_publication
    PublicationTitle.gen(:title => 'Test Publication')
  end

  def gen_biomedical_terms
    puts "** Enter: gen_biomedical_terms" if @debugging
    HierarchyEntry.gen(:hierarchy => Resource.ligercat.hierarchy, :name => @sname, :identifier => @id, :taxon_concept => @tc)
  end

  #
  # Denormalized Tables
  #
  def gen_random_hierarchy_image
    puts "** Enter: gen_random_hierarchy_image" if @debugging
    # TODO - we really don't want to denormalize the names, so remove them (but check that this will work!)
    options = {:data_object => @image_objs.last,
                :name => @sname.italicized,
                :hierarchy_entry => @tc.hierarchy_entries[0],
                :hierarchy => @tc.hierarchy_entries[0].hierarchy,
                :taxon_concept => @tc }
    RandomHierarchyImage.gen(options)
  end

  def add_data_objects_taxon_concepts
    @tc.data_objects.each do |obj|
      unless DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(@tc.id, obj.id)
        DataObjectsTaxonConcept.gen(:taxon_concept => @tc, :data_object => obj)
      end
    end
  end

  def build_entry_in_hierarchy(options)
    puts "**** Enter: build_entry_in_hierarchy" if @debugging
    raise "Cannot build a HierarchyEntry without depth, TaxonConcept, and Name" unless @depth && @tc && @sname
    options[:hierarchy] ||= @hierarchy
    options[:rank_id] ||= Rank.find_by_translated(:label, @rank).id rescue nil
    return build_hierarchy_entry(@depth, @tc, @sname, options)
  end

  # TODO - this is one of the slowest events (and it's called a lot!)
  def build_object_in_event(type, description, options = {})
    puts "**** Enter: build_object_in_event" if @debugging
    options[:event] ||= @event
    options[:hierarchy_entry] ||= @he
    build_data_object(type, description, options)
  end

  def set_default_options(options)
    puts "** Enter: set_default_options" if @debugging
    @attri        = options[:attribution]     || FactoryGirl.generate(:attribution)
    @bhl          = options[:bhl]             || [{:publication => 'Great Big Journal of Fun', :page => 42},
                                                  {:publication => 'Great Big Journal of Fun', :page => 44},
                                                  {:publication => 'The Journal You Cannot Afford', :page => 1}]
    @common_names = options[:common_names]    || [] # MOST entries should NOT have a common name.
    @comments     = options[:comments]        || [{}, {}]
    @canon        = options[:canonical_form]  || FactoryGirl.generate(:scientific_name)
    @ranked_canonical_form = options[:ranked_canonical_form] || @canon
    @complete     = options[:scientific_name] || "#{@canon} #{@attri}".strip
    @depth        = options[:depth]
    @event        = options[:event]           || default_harvest_event # Note this method is in eol_spec_helper
    @flash        = options[:flash]           || [{}] # Array with one empty hash, which we will populate with defaults:
    @hierarchy    = options[:hierarchy]
    @id           = options[:id]
    @images       = options[:images]          || [{}, {}]
    @images       = testing_images if @images == :testing
    @image_objs   = [] # These are the ACTUAL DataObjects, for convenience and speed (@tc.images w/ use DB).
    @italicized   = options[:italicized]
    @iucn_status  = options[:iucn_status]
    @biomedical_terms = options[:biomedical_terms]
    @parent_hierarchy_entry_id = options[:parent_hierarchy_entry_id]
    @rank         = options[:rank]
    @sounds       = options[:sounds]          || [{}]
    @toc          = options[:toc]             || default_toc_option
    @vetted       = (options[:vetted] and ['trusted', 'untrusted', 'unknown'].include? options[:vetted]) ? options[:vetted] : 'trusted'
    @youtube      = options[:youtube]         || [{}] # Array with one empty hash, which we will populate with defaults:
    @he           = options[:hierarchy_entry]
  end

  def default_toc_option
    toc = [{:toc_item => TocItem.overview, :description => "This is an overview of the <b>#{@canon}</b> hierarchy entry."},
            {:toc_item => TocItem.find_by_translated(:label, 'Description'), :description => "This is an description of the <b>#{@canon}</b> hierarchy entry."}]
    # Add more toc items:
    (2).times do
      toc << {} # Default values are applied below.
    end
    return toc
  end

  def testing_images
    images = [{:num_comments => 12}] # One "normal" image, lots of comments, everything else default.
    # So, every TC (which doesn't have a predefined list of images) will have each of the following, making
    # testing easier:
    images << {:description => 'inappropriate', :object_cache_url => FactoryGirl.generate(:image),
                :vetted => Vetted.inappropriate}
    images << {:description => 'untrusted', :object_cache_url => FactoryGirl.generate(:image),
                :vetted => Vetted.untrusted}
    images << {:description => 'unknown',   :object_cache_url => FactoryGirl.generate(:image),
                :vetted => Vetted.unknown}
    images << {:description => 'invisible', :object_cache_url => FactoryGirl.generate(:image),
                :visibility => Visibility.invisible}
    images << {:description => 'preview', :object_cache_url => FactoryGirl.generate(:image),
                :visibility => Visibility.preview}
    images << {:description => 'invisible, unknown',
                :object_cache_url => FactoryGirl.generate(:image), :visibility => Visibility.invisible,
                :vetted => Vetted.unknown}
    images << {:description => 'invisible, untrusted',
                :object_cache_url => FactoryGirl.generate(:image), :visibility => Visibility.invisible,
                :vetted => Vetted.untrusted}
    images << {:description => 'preview, unknown',
                :object_cache_url => FactoryGirl.generate(:image), :visibility => Visibility.preview,
                :vetted => Vetted.unknown}
    return images
  end
end
