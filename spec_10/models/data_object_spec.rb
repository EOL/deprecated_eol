require File.dirname(__FILE__) + '/../spec_helper'

def prep_thumbs
  @content_server_match = $CONTENT_SERVERS[0] + $CONTENT_SERVER_CONTENT_PATH
  @test_int = 2000112212341111
  @test_str = DataObject.cache_path(@test_int)
  # So, Unless we only have one server, this will strip off the number in the first part of the name (ie: content1.eol.org)
  @content_server_match.sub(/\d+\./, '') unless $CONTENT_SERVERS.length == 1
  @dato = mock_dato
  @mock_data_type = mock_model(DataType)
  @mock_data_type.stub!(:label).and_return('Flash')
  @dato.stub!(:data_type).and_return(@mock_data_type)
  @dato.stub!(:thumbnail_cache_url).and_return(:thumby)
  @dato.stub!(:object_cache_url).and_return(@test_int)
  @dato.stub!(:has_thumbnail_cache?).and_return(false)
  @dato.stub!(:has_object_cache_url?).and_return(false)
  DataObject.stub!(:image_cache_path).and_return("#{$CONTENT_SERVERS[0]}#{$CONTENT_SERVER_CONTENT_PATH}/foo_small.png")
end

def mock_dotag(key, value)
  mock = mock_model(DataObjectTag)
  mock.stub!(:key).and_return(key)
  mock.stub!(:value).and_return(value)
  return mock
end

def mock_dato
    @language  = mock_model(Language)
    @mime_type = mock_model(MimeType)
    @data_type = mock_model(DataType)
    @license   = mock_model(License)
    DataObject.create(:rights_statement => '',
      :rights_holder => '',
      :thumbnail_cache_url => '',
      :mime_type_id => @mime_type.id,
      :location => '',
      :latitude => 0,
      :object_created_at => '',
      :created_at => '',
      :guid => '',
      :data_type_id => @data_type.id,
      :object_title => '',
      :object_modified_at => '',
      :bibliographic_citation => '',
      :updated_at => '',
      :source_url => '',
      :altitude => 0,
      :license_id => @license.id,
      :vetted_id => 2,
      :language_id => @language.id,
      :object_url => '',
      :data_rating => 0,
      :description => '',
      :thumbnail_url => '',
      :longitude => 0,
      :object_cache_url => '',
      :visibility_id => 1)
end

describe DataObject, '#to_s' do
  it 'should show the id for to_s (and be short)' do
    @dato = mock_dato
    @dato.to_s.should match(/#{@dato.id}/)
    @dato.to_s.length.should < 30
  end
end

# TODO - DataObject.search_by_tag needs testing, but comments in the file suggest it will be changed significantly.
# TODO - DataObject.search_by_tags needs testing, but comments in the file suggest it will be changed significantly.

describe DataObject, 'tagging' do

  before(:each) do
    @dato = mock_dato
    @user = mock_user
    @tag1 = mock_dotag(:foo, :bar)
    @tag2 = mock_dotag(:foo, :baz)
    @tag3 = mock_dotag(:boozer, :brimble)
  end

  it 'should delegate instance #tag to Class#tag' do
    DataObject.should_receive(:tag).with(@dato, :key, :values, :user).and_return(:i_like_symbols)
    @dato.tag(:key, :values, :user).should == :i_like_symbols
  end

  it 'should delegate public_tags to DataObjectTags#public_tags_for_data_object' do
    DataObjectTags.should_receive(:public_tags_for_data_object).with(@dato).and_return(:hello_there)
    @dato.public_tags.should == :hello_there
  end

  it 'should delegate private_tags, user_tags, and users_tags to DataObjectTags#private_tags.find_all_by_data_object_id_and_user_id' do
    mock_array = mock_model(Array)
    mock_array.should_receive(:find_all_by_data_object_id_and_user_id).with(@dato.id, @user.id).exactly(3).times.and_return(:final_answer)
    DataObjectTags.should_receive(:private_tags).exactly(3).times.and_return(mock_array)
    @dato.private_tags(@user).should == :final_answer
    @dato.user_tags(@user).should == :final_answer
    @dato.users_tags(@user).should == :final_answer
  end

  it 'should create a tag hash' do
    @dato.should_receive(:tags).and_return([@tag1, @tag2, @tag3])
    result = @dato.tags_hash
    result[:foo].should    == [:bar, :baz]
    result[:boozer].should == [:brimble]
  end

  it 'should create tag keys' do
    @dato.should_receive(:tags).and_return([@tag1, @tag2, @tag3])
    @dato.tag_keys.should == [:foo, :boozer]
  end

end

describe DataObject, '#image?' do

  before(:each) do
    @dato = mock_dato
  end

  it 'should return true if this is an image' do
    @dato.should_receive(:data_type_id).and_return(2)
    DataType.should_receive(:image_type_ids).and_return([1, 2, 3])
    @dato.image?.should be_true
  end

  it 'should return false if this is NOT an image' do
    @dato.should_receive(:data_type_id).and_return(4)
    DataType.should_receive(:image_type_ids).and_return([1, 2, 3])
    @dato.image?.should_not be_true
  end

end

describe DataObject, '#video_url' do
  before(:each) do
    prep_thumbs
  end

  it 'should use object_url if non-flash' do
    @mock_data_type.should_receive(:label).and_return('Something else')
    @dato.should_receive(:object_url).and_return(:happy_days)
    @dato.video_url.should == :happy_days
  end

  it 'should use object_cache_url (plus .flv) if available' do
    @dato.should_receive(:has_object_cache_url?).and_return(true)
    @dato.video_url.should == "#{@test_str}.flv"
  end

  it 'should return empty string if no thumbnail (when Flash)' do
    @dato.should_receive(:has_object_cache_url?).and_return(false)
    @dato.video_url.should == ''
  end

  it 'should use content servers' do
    @dato.should_receive(:has_object_cache_url?).and_return(true)
    @dato.video_url.should match(/#{@content_server_match}/)
  end

end

describe DataObject, '#image_cache_path' do
  before(:each) { @big_int = 20081014234567 }
  it 'should grab next Content Server' do
    ContentServer.should_receive(:next).and_return('something')
    DataObject.image_cache_path(@big_int).should match /something/
  end
  it 'should include path passed in as third arg' do
    ContentServer.should_receive(:next).and_return('something')
    DataObject.image_cache_path(@big_int, nil, '/some_path').should match(/something\/some_path/)
  end
  it 'should default path to $CONTENT_SERVER_CONTENT_PATH' do
    DataObject.image_cache_path(@big_int).should match(/#{$CONTENT_SERVER_CONTENT_PATH}/)
  end
  it 'should parse out the integer passed in as first arg into path scheme' do
    DataObject.image_cache_path(@big_int).should match(/2008\/10\/14\/23\/4567/)
  end
  it 'should add _SIZE.png to the end, passed in as second arg' do
    DataObject.image_cache_path(@big_int, :some_size).should match(/_some_size\.png/)
  end
  it 'should default size to :large' do
    DataObject.image_cache_path(@big_int).should match(/_large\.png/)
  end
end

describe DataObject, '#thumb_or_object' do
  before(:each) { prep_thumbs }
  it 'should check cache' do
    @dato.should_receive(:has_thumbnail_cache?).and_return(true)
    @dato.thumb_or_object
  end
  it 'should use cache if exists' do
    @dato.should_receive(:has_thumbnail_cache?).and_return(true)
    @dato.should_receive(:thumbnail_cache_url).and_return(:foo)
    DataObject.should_receive(:image_cache_path).with(:foo, :whatever).and_return :success
    @dato.thumb_or_object(:whatever).should == :success
  end
  it 'should revert to object if no cache' do
    @dato.should_receive(:has_thumbnail_cache?).and_return(false)
    @dato.should_receive(:object_cache_url).and_return(:bar)
    DataObject.should_receive(:image_cache_path).with(:bar, :whatever).and_return :ariba
    @dato.thumb_or_object(:whatever).should == :ariba
  end
  it 'should pass size through' do
    @dato.should_receive(:has_thumbnail_cache?).and_return(false)
    @dato.should_receive(:object_cache_url).and_return(:whatever)
    DataObject.should_receive(:image_cache_path).with(:whatever, :some_size).and_return :aricibo
    @dato.thumb_or_object(:some_size).should == :aricibo
  end
  it 'should deafult size to :large' do
    @dato.should_receive(:has_thumbnail_cache?).and_return(false)
    @dato.should_receive(:object_cache_url).and_return(:whatever)
    DataObject.should_receive(:image_cache_path).with(:whatever, :large).and_return :arctangent
    @dato.thumb_or_object.should == :arctangent
  end
end

describe DataObject, '(smart* methods)' do
  before (:each) { prep_thumbs }
  it '#smart_thumb should call thumb_or_object with :small' do
    @dato.should_receive(:thumb_or_object).with(:small).and_return :worked
    @dato.smart_thumb.should == :worked
  end
  it '#smart_medium_thumb should call thumb_or_object with :medium' do
    @dato.should_receive(:thumb_or_object).with(:medium).and_return :worked
    @dato.smart_medium_thumb.should == :worked
  end
  it '#smart_image should call thumb_or_object with default' do
    @dato.should_receive(:thumb_or_object).with().and_return :worked
    @dato.smart_image.should == :worked
  end
end

describe DataObject, '#map_image' do
  before(:each) do
    prep_thumbs
    @object_url = 'some/object/url'
    @cache_url  = 'some/cache/url'
    @dato.stub!(:object_url).and_return(@object_url)
    @dato.stub!(:object_cache_url).and_return(@cache_url)
  end

  it 'should use object_url if cache is blank and we don\'t $PREFER_REMOTE_IMAGES)' do
    $PREFER_REMOTE_IMAGES = true
    @dato.stub!(:object_cache_url).and_return('') # stubbed because it may never get called.
    @dato.map_image.should == @object_url
  end

  it 'should use object_url if we $PREFER_REMOTE_IMAGES and object_url is non-blank' do
    $PREFER_REMOTE_IMAGES = true
    @dato.map_image.should ==  @object_url
  end

  it 'should use object_url if cache is blank and object_url is blank ... even though this is useless' do
    @dato.stub!(:object_url).and_return('') # stubbed because it may never get called.
    @dato.stub!(:object_cache_url).and_return('') # stubbed because it may never get called.
    @dato.map_image.should == ""
  end

  it 'should use cache_path plus png if we $PREFER_REMOTE_IMAGES but object_url is blank' do
    $PREFER_REMOTE_IMAGES = true
    @dato.should_receive(:object_url).and_return('')
    DataObject.should_receive(:cache_path).with(@cache_url).and_return('great')
    @dato.map_image.should == 'great.png'
  end

  it 'should use image_cache_path (plus .png) if we don\'t $PREFER_REMOTE_IMAGES and cache is non-blank' do
    $PREFER_REMOTE_IMAGES = false
    DataObject.should_receive(:cache_path).with(@cache_url).and_return 'win'
    @dato.map_image.should == 'win.png'
  end

end

describe DataObject, 'vetting' do

  before(:each) do
    @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
  end

  it '#create_valid should be valid' do
    @dato.should be_valid
  end

  it 'should be able to be vetted' do
    @dato.should_not be_vetted
    @dato.is_vetted?.should be_false
    
    @dato.vet!
    @dato.vetted.should == Vetted.trusted
    @dato.should be_vetted
    @dato.is_vetted?.should be_true
  end

  it 'should alias is_vetted? to vetted?' do
    mock_trust = mock_model(Vetted)
    @dato.vetted_id = mock_trust.id
    Vetted.should_receive(:trusted).and_return(mock_trust)
    @dato.is_vetted?.should be_true
  end

  it 'should be able to be un-vetted' do
    @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
    @dato.should_not be_vetted
    @dato.is_vetted?.should be_false

    @dato.unvet!
    @dato.vetted.should == Vetted.untrusted
    @dato.should_not be_vetted
    @dato.is_vetted?.should be_false
  end

  it 'should set curated bit' do
    @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
    @dato.curated.should be_false
    
    @dato.vet!
    @dato.curated.should be_true
    
    @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
    @dato.curated.should be_false
    
    @dato.unvet!
    @dato.curated.should be_true

    @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
    @dato.curated.should be_false
    
    @dato.hide!
    @dato.curated.should be_true

    @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
    @dato.curated.should be_false
    
    @dato.show!
    @dato.curated.should be_true
  end
  
  
end

describe DataObject, 'comments' do

  before(:each) do
    @dato = mock_dato
    @user = mock_user
    @user.comments.stub!(:reload)
  end

  it 'should have a #comment method' do
    @dato.should respond_to(:comment)
  end

  it 'should add comment to comments on #comment' do
    @dato.comment(@user, 'this is a test body')
    @dato.comments.last.body.should == 'this is a test body'
    @dato.comments.last.user_id.should == @user.id
  end

  it 'should reload user comments automatically' do
    @user.comments.should_receive(:reload)
    @dato.comment(@user, 'this is a test body')
  end

  it '#comment should return the created comment' do
    comment = @dato.comment(@user, 'this is a test body')
    comment.user_id = @user.id
    comment.parent_id.should == @dato.id
    comment.parent_type.should == 'DataObject'
    comment.body.should == 'this is a test body'
    comment.visible_at <= Time.now
    comment.created_at <= Time.now
    comment.updated_at <= Time.now
  end

  it 'should have visible_comments' do
    comments = []
    @dato.comments = []
    @dato.save!
    4.times do
      @dato.comments << Comment.new(:body => 'whatever', :user_id => @user.id, :visible_at => Time.now)
    end
    @dato.save!
    @dato.comments.length.should == 4
    @dato.visible_comments.length.should == 4
    @dato.comments << Comment.new(:body => 'whatever', :user_id => @user.id, :visible_at => 1.days.from_now)
    @dato.comments.length.should == 5
    @dato.visible_comments.length.should == 4
  end

end

describe DataObject, 'with text fixtures' do

  fixtures :data_objects, :licenses, :agents_data_objects, :data_objects_taxa, :taxa, :taxon_concepts, :agents, :data_objects_table_of_contents, :toc_items

  it 'should find our preview text' do
    DataObject.for_taxon(taxon_concepts(:cafeteria), :text, {:toc_id => data_objects_table_of_contents(:text_preview).toc_id, :agent => agents(:quentin)}).should == [data_objects(:text_preview)]
  end

  it 'should find unknown and untrusted overview text when user preferences allow it' do
    user = mock_user
    user.should_receive(:show_unvetted?).at_least(1).times.and_return(true)
    DataObject.for_taxon(taxon_concepts(:cafeteria), :text, {:toc_id => toc_items(:table_of_contents_1).id, :user => user}).should ==
      [data_objects(:txt_cafeteria_overview), data_objects(:txt_caf_untrusted_overview), data_objects(:txt_caf_unknown_overview)]
  end

  it 'should show invisible overview text to a curator within their clade' do
    user = mock_user
    user.should_receive(:is_curator?).at_least(1).times.and_return(true)
    user.should_receive(:can_curate?).with(taxon_concepts(:cafeteria)).at_least(1).times.and_return(true)
    DataObject.for_taxon(taxon_concepts(:cafeteria), :text, {:toc_id => toc_items(:table_of_contents_1).id, :user => user}).should ==
      [data_objects(:txt_cafeteria_overview), data_objects(:txt_caf_invisible_overview)]
  end

  it 'should find (one) overview TOC' do
    dato = DataObject.for_taxon(taxon_concepts(:cafeteria), :text, {:toc_id => toc_items(:table_of_contents_1).id})
    dato.should_not be_nil
    dato.length.should == 1
    dato[0].description.should == data_objects(:txt_cafeteria_overview).description
  end

  it 'should be able to add fake authors' do
    dato = DataObject.find(data_objects(:txt_cafeteria_overview))
    dato.authors.should_not be_nil
    dato.authors.length.should_not == 0
    fake_agent = Agent.new(:full_name => 'Foo', :homepage => 'bar')
    dato.fake_author(:full_name => fake_agent.full_name, :homepage => fake_agent.homepage)
    dato.authors.last.should share_attributes_with(fake_agent)
  end

end

describe DataObject, 'with image fixtures' do

  fixtures :data_objects, :licenses, :agents_data_objects, :data_objects_taxa, :taxa, :taxon_concepts, :agents, :taxon_concept_names

  it 'should find our preview images' do
    images = DataObject.for_taxon(taxon_concepts(:cafeteria), :image, :agent => agents(:quentin))
    images.should include_id_of(data_objects(:first_preview))
    images.should include_id_of(data_objects(:second_preview))
    images.length.should_not == 2 # Meaning, there should be other images there, too!
  end

end

describe DataObject, '#for_taxon (and subfunctions)' do

  before(:each) do
    @dato = DataObject.new
    @taxon = mock_model(TaxonConcept)
    @mock_trusted = mock_model(DataObject)
    @mock_untrusted = mock_model(DataObject)
    @mock_unknown = mock_model(DataObject)
    @mock_trusted.stub!(:vetted_id).and_return(Vetted.trusted.id)
    @mock_untrusted.stub!(:vetted_id).and_return(Vetted.untrusted.id)
    @mock_unknown.stub!(:vetted_id).and_return(Vetted.unknown.id)
    @taxon.stub!(:includes_unvetted=).with(true)
    @taxon.stub!(:hierarchy_entries).and_return([])
    @user = mock_user
    # To avoid actually looking at the agent or anything else:
    DataObject.stub!(:build_query).and_return('whatever')
  end

  it 'should call build_query with the same args' do
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    DataObject.should_receive(:build_query).with(@taxon, :map, :user => @user).and_return('whatever')
    DataObject.for_taxon(@taxon, :map, :user => @user).should == [@mock_trusted]
  end

  it 'should create a user if none is specified' do
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    User.should_receive(:create_new).and_return(@user)
    DataObject.for_taxon(@taxon, :map).should == [@mock_trusted]
  end

  it 'should NOT use TocItem#find_by_sql instead of DataObject when type is text but toc_id is specified' do
    DataObject.should_not_receive(:cached_images_for_taxon)
    TocItem.should_not_receive(:find_by_sql)
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    DataObject.for_taxon(@taxon, :text, :toc_id => 1).should == [@mock_trusted]
  end

  it 'should use TocItem#find_by_sql instead of DataObject when type is text' do
    DataObject.should_not_receive(:cached_images_for_taxon)
    TocItem.should_receive(:find_by_sql).and_return([@mock_trusted])
    DataObject.for_taxon(@taxon, :text).should == [@mock_trusted]
  end

  it 'should NOT call #cached_images_for_taxon from #for_taxon if the type is not image' do
    DataObject.should_not_receive(:cached_images_for_taxon)
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    DataObject.for_taxon(@taxon, :map).should == [@mock_trusted]
  end

  it 'should NOT call #cached_images_for_taxon from #for_taxon if user wants to see unvetted stuff' do
    @user.should_receive(:show_unvetted?).and_return(true)
    DataObject.should_not_receive(:cached_images_for_taxon)
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    DataObject.for_taxon(@taxon, :image, :user => @user)
  end

  it 'should NOT call #cached_images_for_taxon from #for_taxon if user is admin' do
    @user.should_receive(:is_admin?).and_return(true)
    DataObject.should_not_receive(:cached_images_for_taxon)
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    DataObject.for_taxon(@taxon, :image, :user => @user)
  end

  it 'should NOT call #cached_images_for_taxon from #for_taxon if user is curator' do
    @user.should_receive(:is_curator?).and_return(true)
    DataObject.should_not_receive(:cached_images_for_taxon)
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    DataObject.for_taxon(@taxon, :image, :user => @user)
  end

  it 'should NOT call #cached_images_for_taxon from #for_taxon if agent is specified' do
    mock_agent = mock_model(Agent)
    DataObject.should_not_receive(:cached_images_for_taxon)
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    DataObject.for_taxon(@taxon, :image, :agent => mock_agent)
  end

  it 'should call #cached_images_for_taxon from #for_taxon if nothing special is specified' do
    DataObject.should_receive(:cached_images_for_taxon).and_return([@mock_trusted])
    DataObject.for_taxon(@taxon, :image).should == [@mock_trusted]
  end

  it '#cached_images_for_taxon should NOT flag taxon for unvetted with trusted image' do
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    @taxon.should_not_receive(:includes_unvetted=)
    DataObject.cached_images_for_taxon(@taxon).should == [@mock_trusted]
  end

  it '#cached_images_for_taxon should flag taxon for unvetted with unknown image' do
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted, @mock_unknown])
    @taxon.should_receive(:includes_unvetted=).with(true)
    DataObject.cached_images_for_taxon(@taxon).should == [@mock_trusted, @mock_unknown]
  end

  it '#cached_images_for_taxon should flag taxon for unvetted with untrusted image' do
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted, @mock_untrusted])
    @taxon.should_receive(:includes_unvetted=).with(true)
    DataObject.cached_images_for_taxon(@taxon).should == [@mock_trusted, @mock_untrusted]
  end

  it '#cached_images_for_taxon should collect hierarchy_entry ids from taxon' do
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    mock_he    = mock_model(HierarchyEntry)
    @taxon.should_receive(:hierarchy_entries).and_return([mock_he])
    mock_he.should_receive(:id).and_return(16222828)
    DataObject.cached_images_for_taxon(@taxon)
  end

  it 'should use image type ids' do
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    DataType.should_receive(:image_type_ids).and_return([1,2])
    DataObject.cached_images_for_taxon(@taxon)
  end

  it '#cached_images_for_taxon should call the taxon id, of course' do
    DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
    @taxon.should_receive(:id).and_return(101)
    DataObject.cached_images_for_taxon(@taxon)
  end

end

describe DataObject, '#build_query' do

  before(:each) do
    @taxon = mock_model(TaxonConcept)
    @user = mock_user
    @agent = mock_model(Agent)
    # To avoid sub-function:
    DataObject.stub!(:visibility_clause).and_return('whatever')
  end

  it 'should call #isibility_clause and add it to the query' do
    DataObject.should_receive(:visibility_clause).and_return('test for this')
    DataObject.build_query(@taxon, :image, {}).should match(/test for this/)
  end

  it 'should sort the way we want it to' do
    DataObject.build_query(@taxon, :image, {}).should match(/ORDER BY dato\.published, dato\.vetted_id DESC, dato\.data_rating/)
  end

  it 'should NOT select on toc id when toc id is missing' do
    DataObject.build_query(@taxon, :text, {}).should_not match(/AND toc\.id =/)
  end

  it 'should select on toc id when toc is specified' do
    DataObject.build_query(@taxon, :text, :toc_id => 3).should match(/AND toc\.id = 3/)
  end

  it 'should NOT join in toc when type is NOT :text' do
    DataObject.build_query(@taxon, :map, {}).should_not match(/JOIN data_objects_table_of_contents dotoc ON dotoc\.data_object_id = dato.id JOIN table_of_contents toc ON toc\.id = dotoc\.toc_id/)
  end

  it 'should join in toc when type is :text' do
    DataObject.build_query(@taxon, :text, {}).should match(/JOIN data_objects_table_of_contents dotoc ON dotoc\.data_object_id = dato\.id JOIN table_of_contents toc ON toc\.id = dotoc\.toc_id/)
  end

  it 'should NOT join in agents_data_objects when an agent is NOT specified' do
    DataObject.build_query(@taxon, :map, {}).should_not match(/JOIN agents_data_objects ado ON ado\.data_object_id = dato\.id/)
  end

  it 'should join in agents_data_objects when an agent is specified' do
    DataObject.build_query(@taxon, :map, :agent => @agent).should match(/JOIN agents_data_objects ado ON ado\.data_object_id = dato\.id/)
  end

  it '#build_query should NOT add toc.* when type text toc_id is specified' do
    DataObject.build_query(@taxon, :map, :toc_id => 1).should_not match(/toc\.\*/)
  end

  it '#build_query should NOT add toc.* when type is not text' do
    DataObject.build_query(@taxon, :map, {}).should_not match(/toc\.\*/)
  end

  it '#build_query should add toc.* when type is text' do
    DataObject.build_query(@taxon, :text, {}).should match(/toc\.\*/)
  end

end

describe DataObject, '#get_type_ids' do
  it 'should delegate :map to DataType.map_type_ids' do
    DataType.should_receive(:map_type_ids).and_return(:got_it)
    DataObject.get_type_ids(:map).should == (:got_it)
  end
  it 'should delegate :text to DataType.text_type_ids' do
    DataType.should_receive(:text_type_ids).and_return(:good)
    DataObject.get_type_ids(:text).should == (:good)
  end
  it 'should delegate :video to DataType.video_type_ids' do
    DataType.should_receive(:video_type_ids).and_return(:great)
    DataObject.get_type_ids(:video).should == (:great)
  end
  it 'should delegate :image to DataType.image_type_ids' do
    DataType.should_receive(:image_type_ids).and_return(:groovy)
    DataObject.get_type_ids(:image).should == (:groovy)
  end
  it 'should raise an objection to any other type' do
    lambda { DataObject.get_type_ids(:oops) }.should raise_error
  end
end

describe DataObject, '#visibility_clause' do

  before(:each) do
    @taxon = mock_model(TaxonConcept)
    @user = mock_user
    @user.stub!(:show_unvetted?).and_return(false)
    @user.stub!(:is_curator?).and_return(false)
    @user.stub!(:can_curate?).and_return(false)
    @user.stub!(:is_admin?).and_return(false)
    @agent = mock_model(Agent)
    @preview_objects = ActiveRecord::Base.sanitize_sql(['OR (visibility_id = ? AND published IN (0,1)', Visibility.preview.id])
  end

  it 'should show tons of stuff to an admin' do
    @user.should_receive(:is_admin?).and_return(true)
    clause = DataObject.visibility_clause(:user => @user, :taxon => @taxon)
    clause.should match(/visibility_id IN \(#{Visibility.all_ids.join('\s*,\s*')}\)/)
    clause.should match(/#{@preview_objects.gsub(/\(/, '\\(').gsub(/\)/, '\\)')}/)
  end

  it 'should NOT add invisible when user can curate, but not for this taxon' do
    @user.should_receive(:is_curator?).and_return(true)
    @user.should_receive(:can_curate?).with(@taxon).and_return(false)
    clause = DataObject.visibility_clause(:user => @user, :taxon => @taxon)
    clause.should_not match(/visibility_id IN \(#{[Visibility.visible.id, Visibility.invisible.id].join('\s*,\s*')}\)/)
  end

  it 'should add invisible when user can curate taxon' do
    @user.should_receive(:is_curator?).and_return(true)
    @user.should_receive(:can_curate?).with(@taxon).and_return(true)
    clause = DataObject.visibility_clause(:user => @user, :taxon => @taxon)
    clause.should match(/visibility_id IN \(#{[Visibility.visible.id, Visibility.invisible.id].join('\s*,\s*')}\)/)
  end

  it 'should add unvetted stuff for users when show_unvetted? is specified' do
    @user.should_receive(:show_unvetted?).and_return(true)
    clause = DataObject.visibility_clause(:user => @user)
    clause.should match(/vetted_id IN \(#{[Vetted.trusted.id, Vetted.untrusted.id, Vetted.unknown.id].join('\s*,\s*')}\)/)
  end

  it 'should add visibilities for users when show_unvetted? is specified' do
    @user.should_receive(:show_unvetted?).and_return(true)
    clause = DataObject.visibility_clause(:user => @user)
    clause.should match(/vetted_id IN \(#{[Vetted.trusted.id, Vetted.untrusted.id, Vetted.unknown.id].join('\s*,\s*')}\)/)
  end

  it 'should do more if agent is specified' do
    clause = DataObject.visibility_clause(:user => @user, :agent => @agent)
    clause.should match(/vetted_id IN \(#{[Vetted.trusted.id, Vetted.untrusted.id, Vetted.unknown.id].join('\s*,\s*')}\)/)
    clause.should match(/published IN \(1\)/)
    clause.should match(/visibility_id IN \(#{[Visibility.visible.id, Visibility.invisible.id].join('\s*,\s*')}\)/)
    clause.should match(/#{@preview_objects.gsub(/\(/, '\\(').gsub(/\)/, '\\)')}/)
    clause.should match(/AND ado.agent_id = #{@agent.id}/)
  end

  it 'should have sensible defaults' do
    clause = DataObject.visibility_clause(:user => @user)
    clause.should match(/vetted_id IN \(#{Vetted.trusted.id}\)/)
    clause.should match(/published IN \(1\)/)
    clause.should match(/visibility_id IN \(#{Visibility.visible.id}\)/)
  end

end

describe DataObject, 'Agent-related methods:' do

  before(:each) do
    @agent  = mock_model(Agent)
    @agent1 = mock_model(Agent)
    @agent2 = mock_model(Agent)
    @agent3 = mock_model(Agent)
    @author_id = 23 # doesn't really matter what it is
    @source_id = 64 # doesn't really matter what it is
    AgentRole.stub!(:author_id).at_least(1).times.and_return(@author_id)
    AgentRole.stub!(:source_id).at_least(1).times.and_return(@source_id)
    @ado1   = mock_model(AgentsDataObject, :agent_role_id => @author_id, :agent => @agent1)
    @ado2   = mock_model(AgentsDataObject, :agent_role_id => @author_id, :agent => @agent2)
    @ado3   = mock_model(AgentsDataObject, :agent_role_id => @author_id, :agent => @agent3)
    @ado_a  = mock_model(AgentsDataObject, :agent_role_id => @source_id, :agent => @agent3)
    @ado_b  = mock_model(AgentsDataObject, :agent_role_id => @source_id, :agent => @agent2)
    @ado_c  = mock_model(AgentsDataObject, :agent_role_id => @source_id, :agent => @agent1)
    @dato   = mock_dato
    # This kinda sucks.  I'm not sure how else (other than fixtures) to fake this find_all_by_agent_role_id method:
    @mock_array = mock_model(Array)
    @mock_array.stub!(:find_all_by_agent_role_id).with(@author_id).and_return([@ado1, @ado2, @ado3])
    @mock_array.stub!(:find_all_by_agent_role_id).with(@source_id).and_return([@ado_a, @ado_b, @ado_c])
    @dato.stub!(:agents_data_objects).and_return(@mock_array)
  end

  it '#fake_author should be called multiple time and remeber each one' do
    Agent.should_receive(:new).with(:test_options).and_return(:test_agent)
    Agent.should_receive(:new).with(:more_options).and_return(:another_agent)
    @dato.fake_author(:test_options).should == [:test_agent]
    @dato.fake_author(:more_options).should == [:test_agent, :another_agent]
  end

  it '#authors should return a list of agents' do
    @dato.authors.should == [@agent1, @agent2, @agent3]
  end

  it '#authors should handle null agents' do
    @ado2.should_receive(:agent).and_return(nil)
    @dato.authors.should == [@agent1, @agent3]
  end

  it '#authors should add fake authors to #agents' do
    Agent.should_receive(:new).with(:test_options).and_return(@agent)
    @dato.fake_author(:test_options)
    @dato.authors.should == [@agent1, @agent2, @agent3, @agent]
  end

  it '#sources should return a list of agents' do
    @dato.sources.should == [@agent3, @agent2, @agent1]
  end

  it '#sources should handle null agents' do
    @ado_b.should_receive(:agent).and_return(nil)
    @dato.sources.should == [@agent3, @agent1]
  end

  it '#sources should resort to authors when empty' do
    @mock_array.should_receive(:find_all_by_agent_role_id).with(@source_id).and_return([])
    @dato.sources.should == [@agent1, @agent2, @agent3] # This comes from the authors, now.
  end

end

describe DataObject, '#is_curatable_by?' do

  before(:each) do
    @user    = mock_user
    @dato    = mock_dato
    @mock_he = mock_model(HierarchyEntry)
  end

  it 'should be curatable by a user with access' do
    @dato.should_receive(:hierarchy_entries).and_return([@mock_he])
    @user.should_receive(:can_curate?).and_return(true)
    @dato.is_curatable_by?(@user).should == true
  end

  it 'should NOT be curatable by a user WITHOUT access' do
    @dato.should_receive(:hierarchy_entries).and_return([@mock_he])
    @user.should_receive(:can_curate?).and_return(false)
    @dato.is_curatable_by?(@user).should == false
  end

end

describe DataObject, '#taxon_concepts' do

  fixtures :data_objects, :data_objects_taxa, :taxa, :taxon_concepts, :names, :taxon_concept_names
    
  it 'should get all taxon_concepts that a data object is associated with' do
    data_objects(:many_taxa).taxon_concepts.collect {|tc| tc.id }.should ==
      [taxon_concepts(:Archaea).id, taxon_concepts(:Fungi).id, taxon_concepts(:Plantae).id]
  end

end

describe DataObject, '#hierarchy_entries' do

  fixtures :data_objects, :data_objects_taxa, :taxa, :taxon_concepts, :names, :taxon_concept_names, :hierarchy_entries
    
  it 'should get all hierarchy_entries that a data object is associated with' do
    # hierarchy_entries.yml (the fixture) is auto-generated, so I don't want to trust the names:
    he_s = [taxon_concepts(:Archaea), taxon_concepts(:Fungi), taxon_concepts(:Plantae)].collect {|tc| tc.hierarchy_entries}.flatten
    data_objects(:many_taxa).hierarchy_entries.collect {|he| he.id }.should == he_s.collect {|he| he.id}.uniq
  end

end

# == Schema Info
# Schema version: 20080923175821
#
# Table name: data_objects
#
#  id                     :integer(4)      not null, primary key
#  data_type_id           :integer(2)      not null
#  language_id            :integer(2)      not null
#  license_id             :integer(1)      not null
#  mime_type_id           :integer(2)      not null
#  visibility_id          :integer(4)
#  altitude               :float           not null
#  bibliographic_citation :string(300)     not null
#  data_rating            :float           not null
#  description            :text            not null
#  guid                   :string(20)      not null
#  latitude               :float           not null
#  location               :string(255)     not null
#  longitude              :float           not null
#  object_cache_url       :string(255)     not null
#  object_title           :string(255)     not null
#  object_url             :string(255)     not null
#  rights_holder          :string(255)     not null
#  rights_statement       :string(300)     not null
#  source_url             :string(255)     not null
#  thumbnail_cache_url    :string(255)     not null
#  thumbnail_url          :string(255)     not null
#  vetted_id              :integer(1)      not null
#  created_at             :timestamp       not null
#  object_created_at      :timestamp       not null
#  object_modified_at     :timestamp       not null
#  updated_at             :timestamp       not null
# == Schema Info
# Schema version: 20081002192244
#
# Table name: data_objects
#
#  id                     :integer(4)      not null, primary key
#  data_type_id           :integer(2)      not null
#  language_id            :integer(2)      not null
#  license_id             :integer(1)      not null
#  mime_type_id           :integer(2)      not null
#  visibility_id          :integer(4)
#  altitude               :float           not null
#  bibliographic_citation :string(300)     not null
#  data_rating            :float           not null
#  description            :text            not null
#  guid                   :string(32)      not null
#  latitude               :float           not null
#  location               :string(255)     not null
#  longitude              :float           not null
#  object_cache_url       :string(255)     not null
#  object_title           :string(255)     not null
#  object_url             :string(255)     not null
#  rights_holder          :string(255)     not null
#  rights_statement       :string(300)     not null
#  source_url             :string(255)     not null
#  thumbnail_cache_url    :string(255)     not null
#  thumbnail_url          :string(255)     not null
#  vetted_id              :integer(1)      not null
#  created_at             :timestamp       not null
#  object_created_at      :timestamp       not null
#  object_modified_at     :timestamp       not null
#  updated_at             :timestamp       not null
# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_objects
#
#  id                     :integer(4)      not null, primary key
#  data_type_id           :integer(2)      not null
#  language_id            :integer(2)      not null
#  license_id             :integer(1)      not null
#  mime_type_id           :integer(2)      not null
#  vetted_id              :integer(1)      not null
#  visibility_id          :integer(4)
#  altitude               :float           not null
#  bibliographic_citation :string(300)     not null
#  curated                :boolean(1)      not null
#  data_rating            :float           not null
#  description            :text            not null
#  guid                   :string(32)      not null
#  latitude               :float           not null
#  location               :string(255)     not null
#  longitude              :float           not null
#  object_cache_url       :string(255)     not null
#  object_title           :string(255)     not null
#  object_url             :string(255)     not null
#  published              :boolean(1)      not null
#  rights_holder          :string(255)     not null
#  rights_statement       :string(300)     not null
#  source_url             :string(255)     not null
#  thumbnail_cache_url    :string(255)     not null
#  thumbnail_url          :string(255)     not null
#  created_at             :timestamp       not null
#  object_created_at      :timestamp       not null
#  object_modified_at     :timestamp       not null
#  updated_at             :timestamp       not null

