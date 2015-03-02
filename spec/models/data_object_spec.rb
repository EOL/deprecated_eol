require "spec_helper"

describe DataObject do

  before(:all) do
    truncate_all_tables

    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    @taxon_concept = @testy[:taxon_concept]

    @curator         = @testy[:curator]
    @another_curator = create_curator
    
    @dato = DataObject.gen(description: 'That <b>description has unclosed <i>html tags')
    DataObjectsTaxonConcept.gen(taxon_concept_id: @taxon_concept.id, data_object_id: @dato.id)
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild

    @hierarchy_entry = HierarchyEntry.gen
    @image_dato      = @taxon_concept.images_from_solr(100).last

    @big_int = 20081014234567
    @image_cache_path = %r/2008\/10\/14\/23\/4567/
    content_server_match = $CONTENT_SERVER + $CONTENT_SERVER_CONTENT_PATH
    content_server_match.gsub!(/\d+/, '\\d+') # Because we don't care *which* server it hits...
    @content_server_match = %r/#{content_server_match}/
    @flash_dato = DataObject.gen(data_type: DataType.find_by_translated(:label, 'flash'), object_cache_url: @big_int)

    # add user submitted text
    @user = User.gen
    @user_submitted_text = @taxon_concept.add_user_submitted_text(user: @user)
  end

  it "deletes all its collection items" do
    d = DataObject.gen
    collection = Collection.gen
    col_item = CollectionItem.create(collection_id: collection.id, collected_item_id: d.id, 
      collected_item_type: d.class.to_s)
    d.remove_all_collection_items
    expect(CollectionItem.where(id: col_item.id).count).to equal(0)
    collection.destroy
    d.destroy
  end
  
  it "marks itself as unpublished" do
    d = DataObject.gen
    expect(d.published).to be_true
    d.unpublish
    expect(d.published).to be_false
    d.destroy
  end
  
  it "marks all its associations as hidden/untrusted" do
    d = DataObject.gen
    hierarchy_entry = HierarchyEntry.gen
    dohe = DataObjectsHierarchyEntry.create(hierarchy_entry_id: hierarchy_entry.id, data_object_id: d.id,
      vetted_id: Vetted.trusted.id, visibility_id: Visibility.visible.id)
    hierarchy_entry2 = HierarchyEntry.gen
    dohe2 = DataObjectsHierarchyEntry.create(hierarchy_entry_id: hierarchy_entry2.id, data_object_id: d.id,
      vetted_id: Vetted.trusted.id, visibility_id: Visibility.visible.id)
    d.mark_for_all_association_as_hidden_untrusted(@curator)
    dohe.reload
    dohe2.reload
    expect(dohe.vetted_id).to equal(Vetted.untrusted.id)
    expect(dohe.visibility_id).to equal(Visibility.invisible.id)
    expect(dohe2.vetted_id).to equal(Vetted.untrusted.id)
    expect(dohe2.visibility_id).to equal(Visibility.invisible.id)
    d.destroy
    dohe.destroy
    dohe2.destroy
    hierarchy_entry.destroy
    hierarchy_entry2.destroy
  end
  
  it 'should be able to replace wikipedia articles' do
    TocItem.gen_if_not_exists(label: 'wikipedia')

    published_do = build_data_object('Text', 'This is a test wikipedia article content', published: 1, vetted: Vetted.trusted, visibility: Visibility.visible)
    DataObjectsTaxonConcept.gen(taxon_concept_id: @taxon_concept.id, data_object_id: published_do.id)
    published_do.toc_items << TocItem.wikipedia

    preview_do = build_data_object('Text', 'This is a test wikipedia article content', guid: published_do.guid,
                                   published: 1, vetted: Vetted.unknown, visibility: Visibility.preview)
    DataObjectsTaxonConcept.gen(taxon_concept_id: @taxon_concept.id, data_object_id: preview_do.id)
    preview_do.toc_items << TocItem.wikipedia

    published_do.published.should be_true
    # ...This one is failing, but it's quite complicated, so I'm coming back to it:
    preview_do.visibility_by_taxon_concept(@taxon_concept).should == Visibility.preview
    preview_do.vetted_by_taxon_concept(@taxon_concept).should == Vetted.unknown

    preview_do.publish_wikipedia_article(@taxon_concept)
    published_do.reindex
    preview_do.reindex

    published_do.published.should_not be_true
    preview_do.published.should be_true

    published_do.vetted_by_taxon_concept(@taxon_concept).should == Vetted.trusted
    published_do.visibility_by_taxon_concept(@taxon_concept).should == Visibility.visible
  end

 it 'ratings should have a default rating of 2.5' do
   d = DataObject.new
   d.data_rating.should eql(2.5)
 end

 it 'ratings should create new rating' do
   UsersDataObjectsRating.delete_all
   UsersDataObjectsRating.count.should == 0

   d = DataObject.gen
   d.rate(@user,5)

   UsersDataObjectsRating.count.should eql(1)
   d.data_rating.should eql(5.0)
   r = UsersDataObjectsRating.find_by_user_id_and_data_object_guid(@user.id, d.guid)
   r.rating.should eql(5)
 end

 it 'ratings should generate average rating' do
   d = DataObject.gen
   u1 = User.gen
   u2 = User.gen
   d.rate(u1,4)
   d.rate(u2,2)
   d.data_rating.should eql(3.0)
 end

 it "should be able to recalculate rating" do
   d = DataObject.gen
   u1 = User.gen
   u2 = User.gen
   d.data_rating.should == 2.5
   d.data_rating = 0
   d.save!
   d.data_rating.should == 0
   d.recalculate_rating
   d.data_rating.should == 2.5
   d.rate(u1, 4)
   d.rate(u2, 3)
   d.data_rating.should == 3.5
   d.data_rating = 0
   d.save!
   d.data_rating.should == 0
   d.recalculate_rating
   d.data_rating.should == 3.5
 end

 it 'ratings should show rating for old and new version of re-harvested dato' do
   text_dato  = build_data_object('Text', 'some description', toc_item: TocItem.wikipedia)
   image_dato = build_data_object('Image', 'whatever the description may be')
   text_dato.rate(@another_curator, 4)
   image_dato.rate(@another_curator, 4)

   text_dato.data_rating.should eql(4.0)
   image_dato.data_rating.should eql(4.0)

   new_text_dato  = DataObject.build_reharvested_dato(text_dato)
   new_image_dato = DataObject.build_reharvested_dato(image_dato)

   new_text_dato.data_rating.should eql(4.0)
   new_image_dato.data_rating.should eql(4.0)

   new_text_dato.rate(@another_curator, 2)
   new_image_dato.rate(@another_curator, 2)

   new_text_dato.data_rating.should eql(2.0)
   new_image_dato.data_rating.should eql(2.0)
 end

 it 'verifies unique guids per user' do
   UsersDataObjectsRating.delete_all
   d = DataObject.gen
   u = User.gen
   d.rate(u,5)
   UsersDataObjectsRating.count.should eql(1)
   d.rate(u,1)
   UsersDataObjectsRating.count.should eql(1)
 end

  it 'ratings should update existing rating' do
    UsersDataObjectsRating.delete_all
    d = DataObject.gen
    u = User.gen
    d.rate(u,1)
    d.rate(u,5)
    d.data_rating.should eql(5.0)
    UsersDataObjectsRating.count.should eql(1)
    r = UsersDataObjectsRating.find_by_user_id_and_data_object_guid(u.id, d.guid)
    r.rating.should eql(5)
  end

  it 'should know if it is an image map and not a map map' do
    map_dato = DataObject.gen(data_type: DataType.map)
    image_dato = DataObject.gen(data_type: DataType.image)
    image_map_dato = DataObject.gen(data_type: DataType.image, data_subtype: DataType.map)
    map_dato.map?.should be_true
    map_dato.image_map?.should be_false
    image_dato.image_map?.should be_false
    image_dato.image?.should be_true
    image_map_dato.image_map?.should be_true
    image_map_dato.image?.should be_true
    image_map_dato.map?.should be_false
  end

  it 'should return true if this is an image' do
    dato = DataObject.gen(data_type_id: DataType.image_type_ids.first)
    dato.image?.should be_true
  end

  it 'should return false if this is NOT an image' do
    dato = DataObject.gen(data_type_id: DataType.image_type_ids.sort.last + 1) # Clever girl...
    dato.image?.should_not be_true
  end

  it 'should return true if this is a link' do
    dato = DataObject.gen(data_type_id: DataType.text_type_ids.first, data_subtype_id: DataType.link_type_ids.first, source_url: "http://eol.org")
    dato.link?.should be_true
  end

  it 'should return false if this is NOT a link' do
    dato = DataObject.gen(data_type_id: DataType.text_type_ids.first, data_subtype_id: DataType.link_type_ids.sort.last + 1, source_url: "http://eol.org")
    dato.link?.should_not be_true
  end

  describe '#has_thumbnail?' do
    it 'should return true when an image, video or sound object has a thumbnail image' do
      dato = @dato.dup
      [DataType.sound, DataType.video].each do |type|
        dato.data_type = type
        dato.object_cache_url = 0
        dato.thumbnail_cache_url = 123
        dato.has_thumbnail?.should be_true
      end
      [DataType.image].each do |type|
        dato.data_type = type
        dato.object_cache_url = 123
        dato.thumbnail_cache_url = 0
        dato.has_thumbnail?.should be_true
      end
    end
    it 'should return false when an image, video or sound object does not have a thumbnail image' do
      dato = @dato.dup
      [DataType.sound, DataType.video].each do |type|
        dato.data_type = type
        dato.object_cache_url = 123
        dato.thumbnail_cache_url = 0
        dato.has_thumbnail?.should be_false
      end

      dato.data_type = DataType.image
      dato.object_cache_url = 0
      dato.thumbnail_cache_url = 123
      dato.has_thumbnail?.should be_false
    end
    it 'should return false when the object is text' do
      dato = @dato.dup
      dato.data_type = DataType.text
      dato.object_cache_url = 123
      dato.thumbnail_cache_url = 123
      dato.has_thumbnail?.should be_false
    end
  end

  describe '#video_url' do
    it 'should use .ogg file extension for .ogv files' do
      ogg = DataObject.gen(object_url: 'http://example.ogv',
                           object_cache_url: 123,
                           data_type: DataType.video)
      ogg.video_url.should =~ /ogg$/
    end

    it 'should still work* when object url is to a php file' do
      # *it barely works, its totally unreliable and needs to be fixed
      d = DataObject.gen(object_url: 'http://example.php',
                         object_cache_url: 123,
                         data_type: DataType.video,
                         mime_type: MimeType.mp4)
      d.video_url.should =~ /mp4$/
      d.mime_type = MimeType.mov
      d.video_url.should =~ /mov$/
      d.mime_type = MimeType.mpeg
      d.video_url.should =~ /mpeg$/
    end

    it 'should use object_url if non-flash' do
      @dato.data_type = DataType.gen_if_not_exists(label: 'AnythingButFlash')
      @dato.video_url.should == @dato.object_url
    end


    it 'should use object_cache_url (plus .flv) if available' do
      @flash_dato.video_url.should =~ @content_server_match
      @flash_dato.video_url.should =~ /\.flv$/
    end

    it 'should return empty string if no thumbnail (when Flash)' do
      @dato.object_cache_url = nil
      @dato.video_url.should == ''
      @dato.object_cache_url = ''
      @dato.video_url.should == ''
    end

    it 'should use content servers' do
      @flash_dato.video_url.should match(@content_server_match)
    end
  end

  # 'Gofas, S.; Le Renard, J.; Bouchet, P. (2001). Mollusca, <B><I>in</I></B>: Costello, M.J. <i>et al.</i> (Ed.) (2001). <i>European register of marine species: a check-list of the marine species in Europe and a bibliography of guides to their identification.'

  it 'should close tags in data_objects (incl. users)' do
    dato_descr_before = @dato.description
    dato_descr_after  = @dato.description.balance_tags

    dato_descr_after.should == 'That <b>description has unclosed <i>html tags</i></b>'
  end

  describe '#published_refs' do

    let(:dato_with_refs) do
      dato_with_refs = DataObject.gen
      dato_with_refs.add_ref_with_published_and_visibility('published visible reference', 1, Visibility.visible)
      dato_with_refs.add_ref_with_published_and_visibility('published invisible reference', 1, Visibility.invisible)
      dato_with_refs.add_ref_with_published_and_visibility('unpublished visible reference', 0, Visibility.visible)
      dato_with_refs
    end

    subject(:refs) { dato_with_refs.published_refs.map(&:full_reference) }

    it 'should include published visible refs' do
      refs.should include('published visible reference')
    end
    it 'should NOT show invisible references' do
      refs.should_not include('published invisible reference')
    end
    it 'should NOT show unpublished references' do
      refs.should_not include('unpublished visible reference')
    end

  end

  it 'should close tags in references' do
    full_ref         = 'a <b>b</div></HTML><i'
    repaired_ref     = '<div>a <b>b</div></HTML><i</b>'

    @dato.refs << ref = Ref.gen(full_reference: full_ref, published: 1, visibility: Visibility.visible)
    ref_after = @dato.visible_references[0].full_reference.balance_tags
    ref_after.should == repaired_ref
  end

  it 'should delegate #image_cache_path to ContentServer' do
    ContentServer.should_receive(:cache_path).with(:foo, {}).and_return("worked")
    DataObject.image_cache_path(:foo, :large).should == "worked_large.#{$SPECIES_IMAGE_FORMAT}"
  end

  it 'should default to the object_title' do
    dato = DataObject.gen(object_title: 'Something obvious')
    dato.short_title.should == 'Something obvious'
  end

  it 'should resort to the first line of the description if the object_title is empty' do
    dato = DataObject.gen(object_title: '', description: "A long description\nwith multiple lines of stuff")
    dato.short_title.should == "A long description"
  end

  it 'should resort to the first 32 characters (plus three dots) if the decsription is too long and one-line' do
    dato = DataObject.gen(object_title: '', description: "The quick brown fox jumps over the lazy dog, and now is the time for all good men to come to the aid of their country")
    dato.short_title.length.should <= 34
    dato.short_title.should =~ /\.\.\.$/
  end

  # TODO - ideally, this should be something like "Image of Procyon lotor", but that would be a LOT of work to extract
  # froom the data_objects/show view (mainly because it builds links).
  it 'should resort to the data type, if there is no description' do
    dato = DataObject.gen(object_title: '', description: '', data_type: DataType.image)
    dato.short_title.should == "Image"
  end

  it 'should update the Solr record when the object is curated' do
    solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
    solr_connection.delete_all_documents
    solr_connection.get_results("data_type_id:#{DataType.text.id}")['numFound'].should == 0
    @user_submitted_text = @taxon_concept.add_user_submitted_text(user: @user)
    solr_connection.get_results("data_type_id:#{DataType.text.id}")['numFound'].should > 0
    solr_connection.get_results("data_object_id:#{@user_submitted_text.id}")['numFound'] == 1
  end

  it 'should have an activity_log' do
    dato = DataObject.gen
    dato.respond_to?(:activity_log).should be_true
    dato.activity_log.should be_a WillPaginate::Collection
  end

  it 'should add an entry in curated_data_objects_hierarchy_entries when an association is added' do
    CuratedDataObjectsHierarchyEntry.delete_all
    @image_dato.add_curated_association(@user, @hierarchy_entry)
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
    cdohe.should_not == nil
  end

  it '#add_curated_association should add a trusted association if added by full/master curator' do
    CuratedDataObjectsHierarchyEntry.delete_all
    @image_dato.add_curated_association(@curator, @hierarchy_entry)
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
    cdohe.trusted?.should eql(true)
  end

  it '#add_curated_association should add a unreviewed association if added by assistant curator or data object owner' do
    CuratedDataObjectsHierarchyEntry.delete_all
    @image_dato.add_curated_association(@user, @hierarchy_entry)
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
    cdohe.unreviewed?.should eql(true)
  end

  it '#remove_curated_association should raise an exception if a user try to remove an association added by another user' do
    CuratedDataObjectsHierarchyEntry.delete_all
    @image_dato.add_curated_association(@curator, @hierarchy_entry)
    lambda { @image_dato.remove_curated_association(@another_curator, @hierarchy_entry) }.should
      raise_error(EOL::Exceptions::WrongCurator)
  end

  it '#remove_curated_association should remove the entry in curated_data_objects_hierarchy_entries when a user/curator removes their association' do
    CuratedDataObjectsHierarchyEntry.delete_all
    @image_dato.add_curated_association(@curator, @hierarchy_entry)
    cdohe_count = CuratedDataObjectsHierarchyEntry.count(conditions: "hierarchy_entry_id = #{@hierarchy_entry.id}")
    @image_dato.remove_curated_association(@curator, @hierarchy_entry)
    CuratedDataObjectsHierarchyEntry.count(conditions: "hierarchy_entry_id = #{@hierarchy_entry.id}").should ==
        cdohe_count - 1
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
    cdohe.should == nil
  end

  it '#published_entries should read data_objects_hierarchy_entries'

  it '#published_entries should have a user_id on hierarchy entries that were added by curators'

  it '#data_object_taxa should return all associations for the data object' do
    data_object_taxa_count_for_udo = @user_submitted_text.data_object_taxa.count
    @user_submitted_text.reload
    CuratedDataObjectsHierarchyEntry.find_or_create_by_hierarchy_entry_id_and_data_object_id( @hierarchy_entry.id,
        @user_submitted_text.id, data_object_guid: @user_submitted_text.guid, vetted: Vetted.trusted,
        visibility: Visibility.visible, user: @curator)
    DataObject.find(@user_submitted_text).data_object_taxa.count.should == data_object_taxa_count_for_udo + 1
  end

  it '#uncached_data_object_taxa should filter on published, vetted, visibility' do
    second_taxon_concept = build_taxon_concept
    d = DataObject.gen
    d.should_receive(:curated_hierarchy_entries).at_least(1).times.and_return([
      DataObjectTaxon.new(DataObjectsHierarchyEntry.gen(vetted: Vetted.trusted, visibility: Visibility.invisible)),
      DataObjectTaxon.new(DataObjectsHierarchyEntry.gen(vetted: Vetted.unknown, visibility: Visibility.preview)),
      DataObjectTaxon.new(DataObjectsHierarchyEntry.gen(vetted: Vetted.untrusted, visibility: Visibility.visible,
        hierarchy_entry: HierarchyEntry.gen(published: 0)))
      ])
    d.uncached_data_object_taxa.length.should == 3
    d.uncached_data_object_taxa(
      published: true).length.should == 2
    d.uncached_data_object_taxa(
      vetted_id: Vetted.trusted.id).length.should == 1
    d.uncached_data_object_taxa(
      vetted_id: [ Vetted.trusted.id, Vetted.unknown.id ]).length.should == 2
    d.uncached_data_object_taxa(
      vetted_id: [ Vetted.trusted.id, Vetted.unknown.id, Vetted.untrusted.id ]).length.should == 3
    d.uncached_data_object_taxa(
      visibility_id: Visibility.visible.id).length.should == 1
    d.uncached_data_object_taxa(
      visibility_id: [ Visibility.visible.id, Visibility.preview.id ]).length.should == 2
    d.uncached_data_object_taxa(
      visibility_id: [ Visibility.visible.id, Visibility.preview.id, Visibility.invisible.id ]).length.should == 3
    d.uncached_data_object_taxa(
      visibility_id: Visibility.visible.id, vetted_id: Vetted.trusted.id).length.should == 0
    d.uncached_data_object_taxa(
      visibility_id: Visibility.visible.id, vetted_id: Vetted.untrusted.id).length.should == 1
    d.uncached_data_object_taxa(published: true,
      visibility_id: Visibility.visible.id, vetted_id: Vetted.untrusted.id).length.should == 0
  end

  it '#safe_rating should NOT re-calculate ratings that are in the normal range.' do
    dato = DataObject.gen(data_rating: 1.2)
    dato.safe_rating.should == 1.2
  end

  it '#safe_rating should re-calculate really low ratings' do
    dato = DataObject.gen(data_rating: 0.2)
    dato.should_receive(:recalculate_rating).and_return(1.2)
    dato.safe_rating.should == 1.2
  end

  it '#safe_rating should return the minimum rating if the rating is calculated as lower than the minimum rating' do
    dato = DataObject.gen(data_rating: 0.2)
    dato.should_receive(:recalculate_rating).and_return(0.2)
    dato.safe_rating.should == DataObject.minimum_rating
  end

  it '#safe_rating should re-calculate really high ratings' do
    dato = DataObject.gen(data_rating: 5.2)
    dato.should_receive(:recalculate_rating).and_return(1.2)
    dato.safe_rating.should == 1.2
  end

  it '#safe_rating should return the maximum rating if the rating is calculated as higher than the maximum' do
    dato = DataObject.gen(data_rating: 5.2)
    dato.should_receive(:recalculate_rating).and_return(5.2)
    dato.safe_rating.should == DataObject.maximum_rating
  end

  it 'should get remote image if object is pre-defined to be hosted remotely' do
    cp = ContentPartner.gen(full_name: "Discover Life")
    resource = Resource.gen(content_partner_id: cp.id)
    harvest = HarvestEvent.gen(resource_id: resource.id)
    dato = DataObject.gen(object_title: 'xxx Discover Life: Point Map of Gadus morhua yyy', 
                          data_type_id: DataType.image.id,
                          object_cache_url: '200810061224383',
                          object_url: 'http://my.object.url',
                          data_subtype_id: DataType.map.id)
    dohe = DataObjectsHarvestEvent.gen(data_object_id: dato.id, harvest_event_id: harvest.id)
    dato.access_image_from_remote_server?('580_360').should be_true
    dato.access_image_from_remote_server?('260_190').should_not be_true
    dato.access_image_from_remote_server?(:orig).should be_true
  end

  it '#create_user_text should add rights holder only if rights holder not provided, license is not public domain and if it is not a link object' do
    params = { data_type_id: DataType.text.id.to_s,
               license_id: License.public_domain.id.to_s,
               object_title: "",
               bibliographic_citation: "",
               source_url: "",
               rights_statement: "",
               description: "",
               language_id: Language.english.id.to_s,
               rights_holder: ""}
    options = { taxon_concept: TaxonConcept.first,
                user: User.first,
                toc_id: [TocItem.first.id.to_s],
                link_object: false }
    dato = DataObject.create_user_text(params, options)
    dato.rights_holder.should be_blank
    dato.errors.count.should == 1
    dato.should have(1).error_on(:description)
    dato.should_not have(1).error_on(:rights_holder)

    params[:license_id] = License.cc.id.to_s
    dato = DataObject.create_user_text(params, options)
    dato.rights_holder.should == options[:user].full_name
    dato.errors.count.should == 1
    dato.should have(1).error_on(:description)
    dato.should_not have(1).error_on(:rights_holder)

    user_entered_rights_holder = "Someone"
    params[:rights_holder] = user_entered_rights_holder
    dato = DataObject.create_user_text(params, options)
    dato.rights_holder.should == user_entered_rights_holder
    dato.errors.count.should == 1
    dato.should have(1).error_on(:description)
    dato.should_not have(1).error_on(:rights_holder)

    params[:license_id] = License.public_domain.id.to_s
    dato = DataObject.create_user_text(params, options)
    dato.errors.count.should == 2
    dato.should have(1).error_on(:description)
    dato.should have(1).error_on(:rights_holder)

    options[:link_object] = true
    params[:license_id] = nil
    params[:rights_holder] = ''
    dato = DataObject.create_user_text(params, options)
    dato.link?.should be_true
    dato.rights_holder.should == ''
  end

  it '#create_user_text should add proper vetted and visibility statuses to the created link object' do
    assistant_curator = build_curator(@taxon_concept, level: :assistant)
    full_curator = build_curator(@taxon_concept, level: :full)
    master_curator = build_curator(@taxon_concept, level: :master)
    admin = User.gen(admin: 1)
    # Without this, the data object will have errors (url not accessible):
    allow(EOLWebService).to receive(:url_accepted?) { true }
    params = { data_type_id: DataType.text.id.to_s,
               license_id: nil,
               object_title: "",
               bibliographic_citation: "",
               source_url: "http://eol.org",
               rights_statement: "",
               description: "This is link description",
               language_id: Language.english.id.to_s,
               rights_holder: ""}
    options = { taxon_concept: TaxonConcept.first,
                toc_id: [TocItem.first.id.to_s],
                link_object: true }
    options[:user] = @user
    dato = DataObject.create_user_text(params, options)
    dato.link?.should be_true
    expect(dato.users_data_object).to_not be_nil
    dato.users_data_object.vetted_id.should == Vetted.unknown.id
    dato.users_data_object.vetted_id.should == Vetted.unknown.id
    dato.users_data_object.visibility_id.should == Visibility.visible.id
    options[:user] = assistant_curator
    dato = DataObject.create_user_text(params, options)
    dato.link?.should be_true
    dato.users_data_object.vetted_id.should == Vetted.unknown.id
    dato.users_data_object.visibility_id.should == Visibility.visible.id
    options[:user] = full_curator
    dato = DataObject.create_user_text(params, options)
    dato.link?.should be_true
    dato.users_data_object.vetted_id.should == Vetted.trusted.id
    dato.users_data_object.visibility_id.should == Visibility.visible.id
    options[:user] = master_curator
    dato = DataObject.create_user_text(params, options)
    dato.link?.should be_true
    dato.users_data_object.vetted_id.should == Vetted.trusted.id
    dato.users_data_object.visibility_id.should == Visibility.visible.id
    options[:user] = admin
    dato = DataObject.create_user_text(params, options)
    dato.link?.should be_true
    dato.users_data_object.vetted_id.should == Vetted.trusted.id
    dato.users_data_object.visibility_id.should == Visibility.visible.id
  end

  it '#create_user_text should call reload on TaxonConcept, even when fails' do
    new_text_params = {
      data_type_id: DataType.text.id.to_s,
      license_id: nil,
      license_id: License.cc.id.to_s,
      object_title: "",
      bibliographic_citation: "",
      source_url: "http://eol.org",
      rights_statement: "",
      description: "This is link description",
      language_id: Language.english.id.to_s,
      rights_holder: ""
    }
    lambda {
      @taxon_concept.should_receive(:reload).and_return(true)
      DataObject.create_user_text(new_text_params, user: @user, taxon_concept: @taxon_concept)
    }.should raise_error
  end

  it '#latest_published_version_in_same_language should not return itself if the object is unpublished' do
    d = DataObject.gen(published: 1)
    d.latest_published_version_in_same_language.should == d
    d = DataObject.gen(published: 0)
    d.latest_published_version_in_same_language.should == nil
  end

  it 'should know when the rights holder s/b displayed' do
    d = DataObject.gen(license: License.public_domain, rights_holder: '')
    d.show_rights_holder?.should_not be_true
    d.license = License.cc
    d.show_rights_holder?.should be_true
    d.license = License.no_known_restrictions
    d.show_rights_holder?.should_not be_true
  end

  it 'should use the resource rights holder if the data object doesnt have one' do
    # creating a resource for this data object
    hierarchy = Hierarchy.gen
    resource = Resource.gen(hierarchy: hierarchy)
    hierarchy_entry = HierarchyEntry.gen(hierarchy: hierarchy)
    data_object = DataObject.gen    
    DataObjectsHierarchyEntry.gen(hierarchy_entry: hierarchy_entry, data_object: data_object)
    data_object.update_column(:rights_holder, '')
    resource.update_column(:rights_holder, nil)
    data_object.rights_holder_for_display.should == nil

    resource.update_column(:rights_holder, 'RESOURCE RIGHTS')
    data_object.reload.rights_holder_for_display.should == 'RESOURCE RIGHTS'

    data_object.update_column(:rights_holder, 'OBJECT RIGHTS')
    data_object.reload.rights_holder_for_display.should == 'OBJECT RIGHTS'
  end

  it 'should use the resource rights statement if the data object doesnt have one' do
    # creating a resource for this data object
    hierarchy = Hierarchy.gen
    resource = Resource.gen(hierarchy: hierarchy)
    hierarchy_entry = HierarchyEntry.gen(hierarchy: hierarchy)
    data_object = DataObject.gen    
    DataObjectsHierarchyEntry.gen(hierarchy_entry: hierarchy_entry, data_object: data_object)
    data_object.update_column(:rights_statement, '')
    resource.update_column(:rights_statement, nil)
    data_object.rights_statement_for_display.should == nil

    resource.update_column(:rights_statement, 'RESOURCE STATEMENT')
    data_object.reload.rights_statement_for_display.should == 'RESOURCE STATEMENT'

    data_object.update_column(:rights_statement, 'OBJECT STATEMENT')
    data_object.reload.rights_statement_for_display.should == 'OBJECT STATEMENT'
  end

  it 'should use the resource bibliographic citation if the data object doesnt have one' do
    # creating a resource for this data object
    hierarchy = Hierarchy.gen
    resource = Resource.gen(hierarchy: hierarchy)
    hierarchy_entry = HierarchyEntry.gen(hierarchy: hierarchy)
    data_object = DataObject.gen    
    DataObjectsHierarchyEntry.gen(hierarchy_entry: hierarchy_entry, data_object: data_object)
    data_object.update_column(:bibliographic_citation, '')
    resource.update_column(:bibliographic_citation, nil)
    data_object.bibliographic_citation_for_display.should == nil

    resource.update_column(:bibliographic_citation, 'RESOURCE CITATION')
    data_object.reload.bibliographic_citation_for_display.should == 'RESOURCE CITATION'

    data_object.update_column(:bibliographic_citation, 'OBJECT CITATION')
    data_object.reload.bibliographic_citation_for_display.should == 'OBJECT CITATION'
    Resource.destroy(resource)
  end

  it 'should return proper values for can_be_made_overview_text_for_user' do
    published_do = build_data_object('Text', 'This is a test wikipedia article content', published: 1, vetted: Vetted.trusted, visibility: Visibility.visible)
    DataObjectsTaxonConcept.gen(taxon_concept_id: @taxon_concept.id, data_object_id: published_do.id)
    text = @taxon_concept.data_objects.select{ |d| d.text? && !d.added_by_user? }.last
    text.can_be_made_overview_text_for_user?(@curator, @taxon_concept).should == true
    text.update_column(:published, false)
    @taxon_concept.reload
    text.reload.can_be_made_overview_text_for_user?(@curator, @taxon_concept).should == false  # unpublished
    text.update_column(:published, true)
    text.reload.can_be_made_overview_text_for_user?(@curator, @taxon_concept).should == true  # checking base state
    TaxonConceptExemplarArticle.set_exemplar(@taxon_concept.id, text.id)
    @taxon_concept.reload
    debugger if text.reload.can_be_made_overview_text_for_user?(@curator, @taxon_concept)
    text.reload.can_be_made_overview_text_for_user?(@curator, @taxon_concept).should == false  # already exemplar
    TaxonConceptExemplarArticle.destroy_all
    @taxon_concept.reload
    text.reload.can_be_made_overview_text_for_user?(@curator, @taxon_concept).should == true  # checking base state
    text.data_objects_hierarchy_entries.first.update_attributes(visibility_id: Visibility.preview.id)
    text.reload.can_be_made_overview_text_for_user?(@curator, @taxon_concept).should == false  # preview
    text.data_objects_hierarchy_entries.first.update_attributes(visibility_id: Visibility.invisible.id)
    text.reload.can_be_made_overview_text_for_user?(@curator, @taxon_concept).should == false  # invisible
    text.data_objects_hierarchy_entries.first.update_attributes(visibility_id: Visibility.visible.id)
    text.reload.can_be_made_overview_text_for_user?(@curator, @taxon_concept).should == true
  end

  it 'should replace objects with their latest versions with replace_with_latest_versions!' do
    @image_dato = DataObject.find(@image_dato)
    new_image_dato = DataObject.gen(guid: @image_dato.guid, created_at: Time.now)
    test_array = [ @image_dato ]
    DataObject.replace_with_latest_versions!(test_array)
    test_array.should_not == [ @image_dato ]
    test_array.should == [ new_image_dato ]
  end

  it 'should replace objects with their latest versions with replace_with_latest_versions_no_preload' do
    @image_dato = DataObject.find(@image_dato)
    new_image_dato = DataObject.gen(guid: @image_dato.guid, created_at: Time.now)
    test_array = [ @image_dato ]
    DataObject.replace_with_latest_versions_no_preload(test_array)
    test_array.should_not == [ @image_dato ]
    test_array.should == [ new_image_dato ]
  end

  it 'should create the right sound_url for MP3s with no extension in its object_url' do
    mp3 = DataObject.gen(data_type: DataType.sound, mime_type: MimeType.mp3, object_cache_url: @big_int,
      object_url: "http://api.soundcloud.com/tracks/72574158/download?client_id=ac6cdf58548a238e00b7892c031378ce")
    mp3.sound_url.should =~ /#{ContentServer.cache_path(@big_int)}.mp3/
  end

  it 'should create the right sound_url for WAVs with no extension in its object_url' do
    wav = DataObject.gen(data_type: DataType.sound, mime_type: MimeType.wav, object_cache_url: @big_int,
      object_url: "http://api.soundcloud.com/tracks/50714448/download?client_id=ac6cdf58548a238e00b7892c031378ce")
    wav.sound_url.should =~ /#{ContentServer.cache_path(@big_int)}.wav/
  end

  it 'should recognize when the title is the same as a toc label' do
    d = DataObject.gen(object_title: 'Some test title')
    toc = TocItem.gen_if_not_exists(label: d.object_title)
    TranslatedTocItem.gen(table_of_contents_id: toc.id, language_id: Language.from_iso('ar').id, label: "Arabic TOC label")
    toc.reload

    toc.label.should == d.object_title
    toc.label("ar").should == 'Arabic TOC label'
    d.title_same_as_toc_label(toc).should == true
    d.title_same_as_toc_label(toc, language: Language.english).should == true
    # doesnt matter if the user is using a different language
    d.title_same_as_toc_label(toc, language: Language.from_iso('ar')).should == true
  end

  it 'should add rights, citation and location information to SiteSearch Solr core' do
    solr_api = SolrAPI.new($SOLR_SERVER, $SOLR_SITE_SEARCH_CORE)
    fields_for_searching = [ :object_title, :description, :rights_statement, :rights_holder,
      :bibliographic_citation, :location ]
    # removing underscores as Solr will use them to separate search terms
    d = DataObject.gen(Hash[ fields_for_searching.map{ |att| [ att, att.to_s.delete('_') + 'x' ] } ])
    EOL::Solr::SiteSearchCoreRebuilder.obliterate
    fields_for_searching.each do |att|
      solr_api.get_results("resource_type:DataObject AND keyword_type:#{att} AND keyword:#{att.to_s.delete('_')}x")['numFound'].should == 0
    end
    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
    fields_for_searching.each do |att|
      solr_api.get_results("resource_type:DataObject AND keyword_type:#{att} AND keyword:#{att.to_s.delete('_')}x")['numFound'].should == 1
    end
  end

  context '#owner' do

    it 'should use original object for translations' do
      orig = double(DataObject)
      orig.should_receive(:owner).and_return("me")
      @dato.should_receive(:translated_from).and_return(orig)
      @dato.should_receive(:data_object_translation).and_return(true)
      expect(@dato.owner).to eq("me")
    end

    it 'should prefer the (copyrighted) rights holder' do
      @dato.should_receive(:rights_holder_for_display).at_least(1).times.and_return("Bobby")
      expect(@dato.owner).to eq("&copy; Bobby")
    end

    it 'should not copyright public domain rights holder' do
      @dato.should_receive(:rights_holder_for_display).at_least(1).times.and_return("Bobby")
      @dato.should_receive(:license).at_least(1).times.and_return(License.public_domain)
      expect(@dato.owner).to eq("Bobby")
    end

    # TODO - this is not the best test in the world...
    it 'should use sort_buy_role t ograb first agent' do
      @dato.should_receive(:rights_holder_for_display).and_return("")
      agent = Agent.gen
      agent.should_receive(:full_name).and_return("Someone important")
      ado = double(AgentsDataObject)
      ado.should_receive(:agent).and_return(agent)
      @dato.should_receive(:agents_data_objects).at_least(1).times.and_return([ado])
      AgentsDataObject.should_receive(:sort_by_role_for_owner).and_return([ado])
      expect(@dato.owner).to eq("Someone important")
    end

  end
  
  describe ".destroy_everything" do
       
    it "should call 'destroy_all' for agents_data_objects" do
      subject.agents_data_objects.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for data_objects_hierarchy_entries" do
      subject.data_objects_hierarchy_entries.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for data_objects_taxon_concepts" do
      subject.data_objects_taxon_concepts.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for agents_data_objects" do
      subject.agents_data_objects.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for curated_data_objects_hierarchy_entries" do
      subject.curated_data_objects_hierarchy_entries.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for comments" do
      subject.comments.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for data_objects_table_of_contents" do
      subject.data_objects_table_of_contents.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for data_objects_info_items" do
      subject.data_objects_info_items.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for taxon_concept_exemplar_images" do
      subject.taxon_concept_exemplar_images.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for worklist_ignored_data_objects" do
      subject.worklist_ignored_data_objects.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for collection_items" do
      subject.collection_items.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for curator_activity_logs" do
      subject.curator_activity_logs.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for users_data_objects_ratings" do
      subject.users_data_objects_ratings.should_receive(:destroy_all)
      subject.destroy_everything
    end    
  end

  context '#same_as_last?' do

      before(:each) do
        @last_text = build_data_object( "Text", "sample description", object_title: "sample title")
        udo = UsersDataObject.gen(user_id: User.first.id, data_object_id: @last_text.id, taxon_concept: @taxon_concept)
        @options = {taxon_concept: @taxon_concept, user: User.first }
        @params = { data_object: DataObject.new(data_type_id: DataType.text.id.to_s,
                                               object_title: @last_text.object_title,
                                               description: @last_text.description)}
      end

      it 'fails when adding text with the same title' do
        @params[:data_object][:description]= "different description"
        expect(DataObject.same_as_last?(@params, @options)).to be_true
      end

       it 'fails when adding text with the same description' do
         @params[:data_object][:object_title]= "different title"
         expect(DataObject.same_as_last?(@params, @options)).to be_true
      end

      it 'passes when adding text with the different description and title' do
         @params[:data_object][:object_title]= "different title"
         @params[:data_object][:description]= " different description"
         expect(DataObject.same_as_last?(@params, @options)).to be_false
      end

      it 'passes when dataobjects other than text ' do
        @params[:data_object][:data_type_id]=  DataType.image.id.to_s
        expect(DataObject.same_as_last?(@params, @options)).to be_false
        @params[:data_object][:data_type_id]=  DataType.sound.id.to_s
        expect(DataObject.same_as_last?(@params, @options)).to be_false
        @params[:data_object][:data_type_id]=  DataType.video.id.to_s
        expect(DataObject.same_as_last?(@params, @options)).to be_false
        @params[:data_object][:data_type_id]=  DataType.link.id.to_s
        expect(DataObject.same_as_last?(@params, @options)).to be_false
      end

      it 'passes when a different user adds the same text' do
        @options[:user]=User.gen
        expect(DataObject.same_as_last?(@params, @options)).to be_false
      end

  end

end
