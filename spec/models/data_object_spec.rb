require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../scenario_helpers'

describe DataObject do

  before(:all) do
    truncate_all_tables

    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    @taxon_concept = @testy[:taxon_concept]

    @curator         = @testy[:curator]
    @another_curator = create_curator
    @data_object     = @taxon_concept.add_user_submitted_text(:user => @curator)
    @image_dato      = @taxon_concept.images.last

    @dato = DataObject.gen(:description => 'That <b>description has unclosed <i>html tags')
    DataObjectsTaxonConcept.gen(:taxon_concept_id => @taxon_concept.id, :data_object_id => @data_object.id)
    DataObjectsTaxonConcept.gen(:taxon_concept_id => @taxon_concept.id, :data_object_id => @dato.id)
    @tag1 = DataObjectTag.gen(:key => 'foo',    :value => 'bar')
    @tag2 = DataObjectTag.gen(:key => 'foo',    :value => 'baz')
    @tag3 = DataObjectTag.gen(:key => 'boozer', :value => 'brimble')
    DataObjectTags.gen(:data_object_tag => @tag1, :data_object => @dato)
    DataObjectTags.gen(:data_object_tag => @tag2, :data_object => @dato)
    DataObjectTags.gen(:data_object_tag => @tag3, :data_object => @dato)

    @look_for_less_than_tags = true
    DataObjectTag.delete_all(:key => 'foos', :value => 'ball')
    @tag = DataObjectTag.gen(:key => 'foos', :value => 'ball')
    how_many = (DataObjectTags.minimum_usage_count_for_public_tags - 1)
    # In late April of 2008, we "dialed down" the number of tags that it takes... to one.  Which screws up
    # the tests that assume you need more than one tag to make a tag public.  This logic fixes that, but
    # in a way that's flexible enough that it will still work if we dial it back up.
    if how_many < 1
      how_many = 1
      @look_for_less_than_tags = false
    end
    how_many.times do
      DataObjectTags.gen(:data_object_tag => @tag, :data_object => @dato, :user => User.gen)
    end

    @hierarchy_entry = HierarchyEntry.gen
    @image_dato.add_curated_association(@curator, @hierarchy_entry)

    @big_int = 20081014234567
    @image_cache_path = %r/2008\/10\/14\/23\/4567/
    content_server_match = $CONTENT_SERVERS[0] + $CONTENT_SERVER_CONTENT_PATH
    content_server_match.gsub!(/\d+/, '\\d+') # Because we don't care *which* server it hits...
    @content_server_match = %r/#{content_server_match}/
    @flash_dato = DataObject.gen(:data_type => DataType.find_by_translated(:label, 'flash'), :object_cache_url => @big_int)

  end

  it 'should be able to replace wikipedia articles' do
    TocItem.gen_if_not_exists(:label => 'wikipedia')
    published_do = DataObject.gen(:published => 1, :vetted => Vetted.trusted, :visibility => Visibility.visible)
    published_do.toc_items << TocItem.wikipedia
    preview_do = DataObject.gen(:guid => published_do.guid, :published => 1, :vetted => Vetted.unknown, :visibility => Visibility.preview)
    preview_do.toc_items << TocItem.wikipedia

    published_do.published.should == true
    preview_do.visibility.should == Visibility.preview
    preview_do.vetted.should == Vetted.unknown

    preview_do.publish_wikipedia_article
    published_do.reload
    preview_do.reload

    published_do.published.should == false
    preview_do.published.should == true
    preview_do.visibility.should == Visibility.visible
    preview_do.vetted.should == Vetted.trusted
  end

 it 'ratings should have a default rating of 2.5' do
   d = DataObject.new
   d.data_rating.should eql(2.5)
 end

 it 'ratings should create new rating' do
   UsersDataObjectsRating.count.should eql(0)

   d = DataObject.gen
   u = User.gen
   d.rate(u,5)

   UsersDataObjectsRating.count.should eql(1)
   d.data_rating.should eql(5.0)
   r = UsersDataObjectsRating.find_by_user_id_and_data_object_guid(u.id, d.guid)
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
   text_dato  = @taxon_concept.overview.last
   image_dato = @taxon_concept.images.last

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

 it 'ratings should verify uniqueness of pair guid/user in users_data_objects_ratings' do
   UsersDataObjectsRating.count.should eql(0)
   d = DataObject.gen
   u = User.gen
   d.rate(u,5)
   UsersDataObjectsRating.count.should eql(1)
   d.rate(u,1)
   UsersDataObjectsRating.count.should eql(1)
 end

 it 'ratings should update existing rating' do
   d = DataObject.gen
   u = User.gen
   d.rate(u,1)
   d.rate(u,5)
   d.data_rating.should eql(5.0)
   UsersDataObjectsRating.count.should eql(1)
   r = UsersDataObjectsRating.find_by_user_id_and_data_object_guid(u.id, d.guid)
   r.rating.should eql(5)
 end


  it 'should return true if this is an image' do
    @dato = DataObject.gen(:data_type_id => DataType.image_type_ids.first)
    @dato.image?.should be_true
  end

  it 'should return false if this is NOT an image' do
    @dato = DataObject.gen(:data_type_id => DataType.image_type_ids.sort.last + 1) # Clever girl...
    @dato.image?.should_not be_true
  end

  it 'should use object_url if non-flash' do
    @dato.data_type = DataType.gen_if_not_exists(:label => 'AnythingButFlash')
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

  it 'should use store citable entities in an array' do
    @dato.citable_entities.class.should == Array
  end

  it 'should add an attribution based on data_supplier_agent' do
    supplier = Agent.gen
    @dato.should_receive(:data_supplier_agent).at_least(1).times.and_return(supplier)
    @dato.citable_entities.map {|c| c.display_string }.should include(supplier.full_name)
  end

  it 'should add an attribution based on license' do
    license = License.gen()
    @dato.should_receive(:license).at_least(1).times.and_return(license)
    # Not so please with the hard-coded relationship between project_name and description, but can't think of a better way:
    @dato.citable_entities.map {|c| c.display_string }.should include(license.description)
  end

  it 'should add an attribution based on rights statement (and license description)' do
    rights = 'life, liberty, and the persuit of happiness'
    @dato.should_receive(:rights_statement).at_least(1).times.and_return(rights)
    @dato.citable_entities.map {|c| c.display_string }.should include(rights)
  end

  it 'should add an attribution based on location' do
    location = 'life, liberty, and the persuit of happiness'
    @dato.should_receive(:location).at_least(1).times.and_return(location)
    @dato.citable_entities.map {|c| c.display_string }.should include(location)
  end

  it 'should add an attribution based on Source URL' do
    source = 'http://some.biological.edu/with/good/data'
    @dato.should_receive(:source_url).at_least(1).times.and_return(source)
    @dato.citable_entities.map {|c| c.link_to_url }.should include(source) # Note HOMEPAGE, not project_name
  end

  it 'should add an attribution based on Citation' do
    citation = 'http://some.biological.edu/with/good/data'
    @dato.should_receive(:bibliographic_citation).at_least(1).times.and_return(citation)
    @dato.citable_entities.map {|c| c.display_string }.should include(citation)
  end

  # 'Gofas, S.; Le Renard, J.; Bouchet, P. (2001). Mollusca, <B><I>in</I></B>: Costello, M.J. <i>et al.</i> (Ed.) (2001). <i>European register of marine species: a check-list of the marine species in Europe and a bibliography of guides to their identification.'

  it 'should close tags in data_objects (incl. users)' do
    dato_descr_before = @dato.description
    dato_descr_after  = @dato.description.balance_tags

    dato_descr_after.should == 'That <b>description has unclosed <i>html tags</b></i>'
  end

  it 'should close tags in references' do
    full_ref         = 'a <b>b</div></HTML><i'
    repaired_ref     = '<div>a <b>b</div></HTML><i</b>'

    @dato.refs << ref = Ref.gen(:full_reference => full_ref, :published => 1, :visibility => Visibility.visible)
    ref_after = @dato.visible_references[0].full_reference.balance_tags
    ref_after.should == repaired_ref
  end

  it 'feeds should find text data objects for feeds' do
    res = DataObject.for_feeds(:text, @taxon_concept.id)
    res.class.should == Array
    data_types = res.map {|i| i['data_type_id']}.uniq
    data_types.size.should == 1
    DataType.find(data_types[0]).should == DataType.find_by_translated(:label, "Text")
  end

  it 'feeds should find image data objects for feeds' do
    res = DataObject.for_feeds(:images, @taxon_concept.id)
    res.class.should == Array
    data_types = res.map {|i| i['data_type_id']}.uniq
    data_types.size.should == 1
    DataType.find(data_types[0]).should == DataType.find_by_translated(:label, "Image")
  end

  it 'feeds should find image and text data objects for feeds' do
    res = DataObject.for_feeds(:all, @taxon_concept.id)
    res.class.should == Array
    data_types = res.map {|i| i['data_type_id']}.uniq
    data_types.size.should == 2
    data_types = data_types.map {|i| DataType.find(i).label}.sort
    data_types.should == ["Image", "Text"]
  end

  it 'should delegate #cache_path to ContentServer' do
    ContentServer.should_receive(:cache_path).with(:foo, :bar).and_return(:worked)
    DataObject.cache_path(:foo, :bar).should == :worked
  end

  it 'should default to the object_title' do
    dato = DataObject.gen(:object_title => 'Something obvious')
    dato.short_title.should == 'Something obvious'
  end

  it 'should resort to the first line of the description if the object_title is empty' do
    dato = DataObject.gen(:object_title => '', :description => "A long description\nwith multiple lines of stuff")
    dato.short_title.should == "A long description"
  end

  it 'should resort to the first 32 characters (plus three dots) if the decsription is too long and one-line' do
    dato = DataObject.gen(:object_title => '', :description => "The quick brown fox jumps over the lazy dog, and now is the time for all good men to come to the aid of their country")
    dato.short_title.should == "The quick brown fox jumps over t..."
  end

  # TODO - ideally, this should be something like "Image of Procyon lotor", but that would be a LOT of work to extract
  # froom the data_objects/show view (mainly because it builds links).
  it 'should resort to the data type, if there is no description' do
    dato = DataObject.gen(:object_title => '', :description => '', :data_type => DataType.image)
    dato.short_title.should == "Image"
  end

  # TODO - we need to find a proper solution for the data object index in Solr.
  it 'should update the Solr record when the object is curated'

  it 'should have a feed' do
    dato = DataObject.gen
    dato.respond_to?(:feed).should be_true
    dato.feed.should be_a EOL::Feed
  end

  it 'should add an entry in curated_data_objects_hierarchy_entries when a curator adds an association' do
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
    cdohe.should_not == nil
  end

  it 'should add an entry to the curator activity log when a curator adds an association' do
    type = ChangeableObjectType.curated_data_objects_hierarchy_entry
    type.should_not == nil
    action = Activity.add_association
    action.should_not == nil
    last_action = CuratorActivityLog.last
    last_action.activity.should == action
    last_action.changeable_object_type.should == type
    last_action.user.should == @curator
  end

  it 'should trust associations added by curators' do
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
    cdohe.trusted?.should eql(true)
  end

  it 'should remove the entry in curated_data_objects_hierarchy_entries when a curator removes their association' do
    cdohe_count = CuratedDataObjectsHierarchyEntry.count(:conditions => "hierarchy_entry_id = #{@hierarchy_entry.id}")
    @image_dato.remove_curated_association(@another_curator, @hierarchy_entry)
    CuratedDataObjectsHierarchyEntry.count(:conditions => "hierarchy_entry_id = #{@hierarchy_entry.id}").should ==
        cdohe_count - 1
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
    cdohe.should == nil
  end

  it '#untrust_reasons should return the untrust reasons'

  it '#curate_association should curate the given association'

  it '#published_entries should read data_objects_hierarchy_entries' do
    @data_object.should_receive(:hierarchy_entries).and_return([])
    @data_object.published_entries.should == []
  end

  it '#published_entries should have a user_id on hierarchy entries that were added by curators' do
    @data_object.published_entries.should == []
  end

end
