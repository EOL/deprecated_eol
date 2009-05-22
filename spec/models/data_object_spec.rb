require File.dirname(__FILE__) + '/../spec_helper'

def set_content_variables
  @big_int = 20081014234567
  @image_cache_path = %r/2008\/10\/14\/23\/4567/
  @content_server_match = $CONTENT_SERVERS[0] + $CONTENT_SERVER_CONTENT_PATH
  @content_server_match.gsub(/\d+/, '\\d+') # Because we don't care *which* server it hits...
  @content_server_match = %r/#{@content_server_match}/
  @dato = DataObject.gen(:data_type => DataType.find_by_label('flash'), :object_cache_url => @big_int)
end

def create_user_text_object
  Scenario.load :foundation

  taxon_concept = build_taxon_concept(:rank => 'kingdom', :canonical_form => 'Animalia', :common_name => 'Animals')
  toc_item = TocItem.gen({:label => 'Overview'})
  params = {
    :taxon_concept_id => taxon_concept.id,
    :data_objects_toc_category => { :toc_id => toc_item.id}
  }

  do_params = {
    :license_id => License.find_by_title('public domain').id,
    :language_id => Language.find_by_label('English').id,
    :description => 'a new text object',
    :object_title => 'new title'
  }

  params[:data_object] = do_params

  DataObject.create_user_text(params, User.gen)
end

describe DataObject do

  scenario :foundation # Just so we have DataType IDs and the like.

  describe 'ratings' do

    it 'should have a default rating of 2.5' do
      d = DataObject.new
      d.data_rating.should eql(2.5)
    end

    it 'should create new rating' do
      UsersDataObjectsRating.count.should eql(0)

      d = DataObject.gen
      u = User.gen
      d.rate(u,5)

      UsersDataObjectsRating.count.should eql(1)
      d.data_rating.should eql(5.0)
      r = UsersDataObjectsRating.find_by_user_id_and_data_object_id(u.id, d.id)
      r.rating.should eql(5)
    end

    it 'should generate average rating' do
      d = DataObject.gen
      u1 = User.gen
      u2 = User.gen
      d.rate(u1,4)
      d.rate(u2,2)
      d.data_rating.should eql(3.0)
    end

    it 'should update existing rating' do
      d = DataObject.gen
      u = User.gen
      d.rate(u,1)
      d.rate(u,5)
      d.data_rating.should eql(5.0)
      UsersDataObjectsRating.count.should eql(1)
      r = UsersDataObjectsRating.find_by_user_id_and_data_object_id(u.id, d.id)
      r.rating.should eql(5)
    end

  end

  describe 'user submitted text' do
    it 'should create valid data object' do
      d = create_user_text_object
      d.data_type.label.should == 'Text'
      d.user.should_not eql(nil)
      d.guid.length.should eql(32)
    end

    it 'should update existing data object' do
      Scenario.load :foundation

      taxon_concept = build_taxon_concept(:rank => 'kingdom', :canonical_form => 'Animalia', :common_name => 'Animals')
      toc_item = TocItem.gen({:label => 'Overview'})
      params = {
        :taxon_concept_id => taxon_concept.id,
        :data_objects_toc_category => { :toc_id => toc_item.id}
      }

      do_params = {
        :license_id => License.find_by_title('public domain').id,
        :language_id => Language.find_by_label('English').id,
        :description => 'a new text object',
        :object_title => 'new title'
      }

      params[:data_object] = do_params

      d = DataObject.create_user_text(params, User.gen)
      u = d.user

      params = {
        :taxon_concept_id => taxon_concept.id,
        :data_objects_toc_category => { :toc_id => toc_item.id},
        :id => d.id
      }

      do_params = {
        :license_id => License.find_by_title('public domain').id,
        :language_id => Language.find_by_label('English').id,
        :description => 'a new text object',
        :object_title => 'new title'
      }

      params[:data_object] = do_params

      new_d = DataObject.update_user_text(params,u)
      new_d.guid.should eql(d.guid)
      DataObject.find_all_by_guid(d.guid).length.should eql(2)
      new_d.object_title.should eql(d.object_title)
      new_d.description.should eql(d.description)
      new_d.license_id.should eql(d.license_id)
      new_d.language_id.should eql(d.language_id)
    end
  end

  describe '#to_s' do
    it 'should show the id for to_s (and be short)' do
      @dato = DataObject.gen
      @dato.to_s.should match(/#{@dato.id}/)
      @dato.to_s.length.should < 30
    end
  end

  # TODO - DataObject.search_by_tag needs testing, but comments in the file suggest it will be changed significantly.
  # TODO - DataObject.search_by_tags needs testing, but comments in the file suggest it will be changed significantly.

  describe 'tagging' do

    before(:each) do
      @dato = DataObject.gen
      @user = User.gen
      @tag1 = DataObjectTag.gen(:key => 'foo',    :value => 'bar')
      @tag2 = DataObjectTag.gen(:key => 'foo',    :value => 'baz')
      @tag3 = DataObjectTag.gen(:key => 'boozer', :value => 'brimble')
      DataObjectTags.gen(:data_object_tag => @tag1, :data_object => @dato)
      DataObjectTags.gen(:data_object_tag => @tag2, :data_object => @dato)
      DataObjectTags.gen(:data_object_tag => @tag3, :data_object => @dato)
    end

    it 'should create a tag hash' do
      result = @dato.tags_hash
      result['foo'].should    == ['bar', 'baz']
      result['boozer'].should == ['brimble']
    end

    it 'should create tag keys' do
      @dato.tag_keys.should == ['foo', 'boozer']
    end

    it 'should mark tags as public if added by a curator' do
      tc      = build_taxon_concept
      curator = User.gen
      dato    = tc.images.first # We CANNOT use @dato here, because it doesn't have all of the required
                                # relationships to our TaxonConcept.
      curator.approve_to_curate! tc.entry
      dato.tag 'color', 'blue', curator
      dotag = DataObjectTag.find_by_key_and_value('color', 'blue')
      DataObjectTag.find_by_key_and_value('color', 'blue').is_public.should be_true
    end

  end

  describe 'search_by_tags' do

    before(:each) do
      @look_for_less_than_tags = true
      @dato = DataObject.gen
      DataObjectTag.delete_all(:key => 'foo', :value => 'bar')
      @tag = DataObjectTag.gen(:key => 'foo', :value => 'bar')
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
    end

    it 'should not find tags for which there are less than DEAFAULT_MIN_BLAHBLAHBLHA instances' do
      if @look_for_less_than_tags
        DataObject.search_by_tags([[[:foo, 'bar']]]).should be_empty
      end
    end

    it 'should find tags specifically flagged as public, regardless of count' do
      @tag.is_public = true
      @tag.save!
      DataObject.search_by_tags([[[:foo, 'bar']]]).map {|d| d.id }.should include(@dato.id)
    end

  end

  describe '#image?' do

    it 'should return true if this is an image' do
      @dato = DataObject.gen(:data_type_id => DataType.image_type_ids.first)
      @dato.image?.should be_true
    end

    it 'should return false if this is NOT an image' do
      @dato = DataObject.gen(:data_type_id => DataType.image_type_ids.sort.last + 1) # Clever girl...
      @dato.image?.should_not be_true
    end

  end

  describe '#video_url' do
    before(:each) do
      set_content_variables
    end

    it 'should use object_url if non-flash' do
      @dato.data_type = DataType.gen(:label => 'AnythingButFlash')
      @dato.video_url.should == @dato.object_url
    end



    # This one dosn't work, i was trying to fix it when I had to abort...
    #

    #it 'should use object_cache_url (plus .flv) if available' do
      #@dato.object_cache_url = @image_int
      #debugger
      #@dato.video_url.should =~ /#{@test_str}\.flv$/
    #end

    it 'should return empty string if no thumbnail (when Flash)' do
      @dato.object_cache_url = nil
      @dato.video_url.should == ''
      @dato.object_cache_url = ''
      @dato.video_url.should == ''
    end

    # Also broken but I have NO IDEA WHY, and it's very frustrating.  Clearly my regex above (replacing the
    # number with \d+) isn't working, but WHY?!?

    #it 'should use content servers' do
      #@dato.video_url.should match(@content_server_match)
    #end

  end

  describe 'attributions' do

    before(:each) do
      set_content_variables
    end

    it 'should use Attributions object' do
      some_array = [:some, :array]
      @dato.attributions.class.should == Attributions
    end

    it 'should add an attribution based on data_supplier_agent' do
      supplier = Agent.gen
      @dato.should_receive(:data_supplier_agent).and_return(supplier)
      @dato.attributions.map {|ado| ado.agent }.should include(supplier)
    end

    it 'should add an attribution based on license' do
      license = License.gen()
      @dato.should_receive(:license).and_return(license)
      # Not so please with the hard-coded relationship between project_name and description, but can't think of a better way:
      @dato.attributions.map {|ado| ado.agent.project_name }.should include(license.description)
    end

    it 'should add an attribution based on rights statement (and license description)' do
      rights = 'life, liberty, and the persuit of happiness'
      @dato.should_receive(:rights_statement).and_return(rights)
      @dato.attributions.map {|ado| ado.agent.project_name }.should include(rights << '. ' << @dato.license.description)
    end

    it 'should add an attribution based on location' do
      location = 'life, liberty, and the persuit of happiness'
      @dato.should_receive(:location).at_least(1).times.and_return(location)
      @dato.attributions.map {|ado| ado.agent.project_name }.should include(location)
    end

    it 'should add an attribution based on Source URL' do
      source = 'http://some.biological.edu/with/good/data'
      @dato.should_receive(:source_url).at_least(1).times.and_return(source)
      @dato.attributions.map {|ado| ado.agent.homepage }.should include(source) # Note HOMEPAGE, not project_name
    end

    it 'should add an attribution based on Citation' do
      citation = 'http://some.biological.edu/with/good/data'
      @dato.should_receive(:bibliographic_citation).at_least(1).times.and_return(citation)
      @dato.attributions.map {|ado| ado.agent.project_name }.should include(citation)
    end

  end

  #
  # I haven't touched these yet:
  #
  #
#
#  describe '#image_cache_path' do
#    before(:each) { set_content_variables }
#    it 'should grab next Content Server' do
#      ContentServer.should_receive(:next).and_return('something')
#      DataObject.image_cache_path(@big_int).should match /something/
#    end
#    it 'should include path passed in as third arg' do
#      ContentServer.should_receive(:next).and_return('something')
#      DataObject.image_cache_path(@big_int, nil, '/some_path').should match(/something\/some_path/)
#    end
#    it 'should default path to $CONTENT_SERVER_CONTENT_PATH' do
#      DataObject.image_cache_path(@big_int).should match(/#{$CONTENT_SERVER_CONTENT_PATH}/)
#    end
#    it 'should parse out the integer passed in as first arg into path scheme' do
#      DataObject.image_cache_path(@big_int).should match(@image_cache_path)
#    end
#    it 'should add _SIZE.png to the end, passed in as second arg' do
#      DataObject.image_cache_path(@big_int, :some_size).should match(/_some_size\.png/)
#    end
#    it 'should default size to :large' do
#      DataObject.image_cache_path(@big_int).should match(/_large\.png/)
#    end
#  end
#
#  describe '#thumb_or_object' do
#    before(:each) { set_content_variables }
#    it 'should check cache' do
#      @dato.should_receive(:has_thumbnail_cache?).and_return(true)
#      @dato.thumb_or_object
#    end
#    it 'should use cache if exists' do
#      @dato.should_receive(:has_thumbnail_cache?).and_return(true)
#      @dato.should_receive(:thumbnail_cache_url).and_return('foo')
#      DataObject.should_receive(:image_cache_path).with('foo', :whatever).and_return :success
#      @dato.thumb_or_object(:whatever).should == :success
#    end
#    it 'should revert to object if no cache' do
#      @dato.should_receive(:has_thumbnail_cache?).and_return(false)
#      @dato.should_receive(:object_cache_url).and_return('bar')
#      DataObject.should_receive(:image_cache_path).with('bar', :whatever).and_return :ariba
#      @dato.thumb_or_object(:whatever).should == :ariba
#    end
#    it 'should pass size through' do
#      @dato.should_receive(:has_thumbnail_cache?).and_return(false)
#      @dato.should_receive(:object_cache_url).and_return(:whatever)
#      DataObject.should_receive(:image_cache_path).with(:whatever, :some_size).and_return :aricibo
#      @dato.thumb_or_object(:some_size).should == :aricibo
#    end
#    it 'should deafult size to :large' do
#      @dato.should_receive(:has_thumbnail_cache?).and_return(false)
#      @dato.should_receive(:object_cache_url).and_return(:whatever)
#      DataObject.should_receive(:image_cache_path).with(:whatever, :large).and_return :arctangent
#      @dato.thumb_or_object.should == :arctangent
#    end
#  end
#
#  describe '(smart* methods)' do
#    before (:each) { set_content_variables }
#    it '#smart_thumb should call thumb_or_object with :small' do
#      @dato.should_receive(:thumb_or_object).with(:small).and_return :worked
#      @dato.smart_thumb.should == :worked
#    end
#    it '#smart_medium_thumb should call thumb_or_object with :medium' do
#      @dato.should_receive(:thumb_or_object).with(:medium).and_return :worked
#      @dato.smart_medium_thumb.should == :worked
#    end
#    it '#smart_image should call thumb_or_object with default' do
#      @dato.should_receive(:thumb_or_object).with().and_return :worked
#      @dato.smart_image.should == :worked
#    end
#  end
#
#  describe '#map_image' do
#    before(:each) do
#      set_content_variables
#      @object_url = 'some/object/url'
#      @cache_url  = 'some/cache/url'
#      @dato.stub!(:object_url).and_return(@object_url)
#      @dato.stub!(:object_cache_url).and_return(@cache_url)
#    end
#
#    it 'should use object_url if cache is blank and we don\'t $PREFER_REMOTE_IMAGES)' do
#      $PREFER_REMOTE_IMAGES = true
#      @dato.stub!(:object_cache_url).and_return('') # stubbed because it may never get called.
#      @dato.map_image.should == @object_url
#    end
#
#    it 'should use object_url if we $PREFER_REMOTE_IMAGES and object_url is non-blank' do
#      $PREFER_REMOTE_IMAGES = true
#      @dato.map_image.should ==  @object_url
#    end
#
#    it 'should use object_url if cache is blank and object_url is blank ... even though this is useless' do
#      @dato.stub!(:object_url).and_return('') # stubbed because it may never get called.
#      @dato.stub!(:object_cache_url).and_return('') # stubbed because it may never get called.
#      @dato.map_image.should == ""
#    end
#
#    it 'should use cache_path plus png if we $PREFER_REMOTE_IMAGES but object_url is blank' do
#      $PREFER_REMOTE_IMAGES = true
#      @dato.should_receive(:object_url).and_return('')
#      DataObject.should_receive(:cache_path).with(@cache_url).and_return('great')
#      @dato.map_image.should == 'great.png'
#    end
#
#    it 'should use image_cache_path (plus .png) if we don\'t $PREFER_REMOTE_IMAGES and cache is non-blank' do
#      $PREFER_REMOTE_IMAGES = false
#      DataObject.should_receive(:cache_path).with(@cache_url).and_return 'win'
#      @dato.map_image.should == 'win.png'
#    end
#
#  end
#
#  describe 'vetting' do
#
#    before(:each) do
#      @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
#    end
#
#    it '#create_valid should be valid' do
#      @dato.should be_valid
#    end
#
#    it 'should be able to be vetted' do
#      @dato.should_not be_vetted
#      @dato.is_vetted?.should be_false
#      
#      @dato.vet!
#      @dato.vetted.should == Vetted.trusted
#      @dato.should be_vetted
#      @dato.is_vetted?.should be_true
#    end
#
#    it 'should alias is_vetted? to vetted?' do
#      mock_trust = Vetted.gen
#      @dato.vetted_id = mock_trust.id
#      Vetted.should_receive(:trusted).and_return(mock_trust)
#      @dato.is_vetted?.should be_true
#    end
#
#    it 'should be able to be un-vetted' do
#      @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
#      @dato.should_not be_vetted
#      @dato.is_vetted?.should be_false
#
#      @dato.unvet!
#      @dato.vetted.should == Vetted.untrusted
#      @dato.should_not be_vetted
#      @dato.is_vetted?.should be_false
#    end
#
#    it 'should set curated bit' do
#      @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
#      @dato.curated.should be_false
#      
#      @dato.vet!
#      @dato.curated.should be_true
#      
#      @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
#      @dato.curated.should be_false
#      
#      @dato.unvet!
#      @dato.curated.should be_true
#
#      @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
#      @dato.curated.should be_false
#      
#      @dato.hide!
#      @dato.curated.should be_true
#
#      @dato = DataObject.create_valid! :vetted_id => Vetted.unknown.id
#      @dato.curated.should be_false
#      
#      @dato.show!
#      @dato.curated.should be_true
#    end
#    
#    
#  end
#
#  describe 'comments' do
#
#    before(:each) do
#      @dato = DataObject.gen
#      @user = User.gen
#      @user.comments.stub!(:reload)
#    end
#
#    it 'should have a #comment method' do
#      @dato.should respond_to(:comment)
#    end
#
#    it 'should add comment to comments on #comment' do
#      @dato.comment(@user, 'this is a test body')
#      @dato.comments.last.body.should == 'this is a test body'
#      @dato.comments.last.user_id.should == @user.id
#    end
#
#    it 'should reload user comments automatically' do
#      @user.comments.should_receive(:reload)
#      @dato.comment(@user, 'this is a test body')
#    end
#
#    it '#comment should return the created comment' do
#      comment = @dato.comment(@user, 'this is a test body')
#      comment.user_id = @user.id
#      comment.parent_id.should == @dato.id
#      comment.parent_type.should == 'DataObject'
#      comment.body.should == 'this is a test body'
#      comment.visible_at <= Time.now
#      comment.created_at <= Time.now
#      comment.updated_at <= Time.now
#    end
#
#    it 'should have visible_comments' do
#      comments = []
#      @dato.comments = []
#      @dato.save!
#      4.times do
#        @dato.comments << Comment.new(:body => 'whatever', :user_id => @user.id, :visible_at => Time.now)
#      end
#      @dato.save!
#      @dato.comments.length.should == 4
#      @dato.visible_comments.length.should == 4
#      @dato.comments << Comment.new(:body => 'whatever', :user_id => @user.id, :visible_at => 1.days.from_now)
#      @dato.comments.length.should == 5
#      @dato.visible_comments.length.should == 4
#    end
#
#  end
#
#  describe 'with text fixtures' do
#
#    it 'should find our preview text' do
#      DataObject.for_taxon(taxon_concepts(:cafeteria), :text, {:toc_id => data_objects_table_of_contents(:text_preview).toc_id, :agent => agents(:quentin)}).should == [data_objects(:text_preview)]
#    end
#
#    it 'should find unknown and untrusted overview text when user preferences allow it' do
#      user = User.gen
#      user.should_receive(:show_unvetted?).at_least(1).times.and_return(true)
#      DataObject.for_taxon(taxon_concepts(:cafeteria), :text, {:toc_id => toc_items(:table_of_contents_1).id, :user => user}).should ==
#        [data_objects(:txt_cafeteria_overview), data_objects(:txt_caf_untrusted_overview), data_objects(:txt_caf_unknown_overview)]
#    end
#
#    it 'should show invisible overview text to a curator within their clade' do
#      user = User.gen
#      user.should_receive(:is_curator?).at_least(1).times.and_return(true)
#      user.should_receive(:can_curate?).with(taxon_concepts(:cafeteria)).at_least(1).times.and_return(true)
#      DataObject.for_taxon(taxon_concepts(:cafeteria), :text, {:toc_id => toc_items(:table_of_contents_1).id, :user => user}).should ==
#        [data_objects(:txt_cafeteria_overview), data_objects(:txt_caf_invisible_overview)]
#    end
#
#    it 'should find (one) overview TOC' do
#      dato = DataObject.for_taxon(taxon_concepts(:cafeteria), :text, {:toc_id => toc_items(:table_of_contents_1).id})
#      dato.should_not be_nil
#      dato.length.should == 1
#      dato[0].description.should == data_objects(:txt_cafeteria_overview).description
#    end
#
#    it 'should be able to add fake authors' do
#      dato = DataObject.find(data_objects(:txt_cafeteria_overview))
#      dato.authors.should_not be_nil
#      dato.authors.length.should_not == 0
#      fake_agent = Agent.new(:full_name => 'Foo', :homepage => 'bar')
#      dato.fake_author(:full_name => fake_agent.full_name, :homepage => fake_agent.homepage)
#      dato.authors.last.should share_attributes_with(fake_agent)
#    end
#
#  end
#
#  describe 'with image fixtures' do
#
#    it 'should find our preview images' do
#      images = DataObject.for_taxon(taxon_concepts(:cafeteria), :image, :agent => agents(:quentin))
#      images.should include_id_of(data_objects(:first_preview))
#      images.should include_id_of(data_objects(:second_preview))
#      images.length.should_not == 2 # Meaning, there should be other images there, too!
#    end
#
#  end
#
#  describe '#for_taxon (and subfunctions)' do
#
#    before(:each) do
#      @dato = DataObject.new
#      @taxon = TaxonConcept.gen
#      @mock_trusted = DataObject.gen
#      @mock_untrusted = DataObject.gen
#      @mock_unknown = DataObject.gen
#      @mock_trusted.stub!(:vetted_id).and_return(Vetted.trusted.id)
#      @mock_untrusted.stub!(:vetted_id).and_return(Vetted.untrusted.id)
#      @mock_unknown.stub!(:vetted_id).and_return(Vetted.unknown.id)
#      @taxon.stub!(:includes_unvetted=).with(true)
#      @taxon.stub!(:hierarchy_entries).and_return([])
#      @user = User.gen
#      # To avoid actually looking at the agent or anything else:
#      DataObject.stub!(:build_query).and_return('whatever')
#    end
#
#    it 'should call build_query with the same args' do
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      DataObject.should_receive(:build_query).with(@taxon, :map, :user => @user).and_return('whatever')
#      DataObject.for_taxon(@taxon, :map, :user => @user).should == [@mock_trusted]
#    end
#
#    it 'should create a user if none is specified' do
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      User.should_receive(:create_new).and_return(@user)
#      DataObject.for_taxon(@taxon, :map).should == [@mock_trusted]
#    end
#
#    it 'should NOT use TocItem#find_by_sql instead of DataObject when type is text but toc_id is specified' do
#      DataObject.should_not_receive(:cached_images_for_taxon)
#      TocItem.should_not_receive(:find_by_sql)
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      DataObject.for_taxon(@taxon, :text, :toc_id => 1).should == [@mock_trusted]
#    end
#
#    it 'should use TocItem#find_by_sql instead of DataObject when type is text' do
#      DataObject.should_not_receive(:cached_images_for_taxon)
#      TocItem.should_receive(:find_by_sql).and_return([@mock_trusted])
#      DataObject.for_taxon(@taxon, :text).should == [@mock_trusted]
#    end
#
#    it 'should NOT call #cached_images_for_taxon from #for_taxon if the type is not image' do
#      DataObject.should_not_receive(:cached_images_for_taxon)
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      DataObject.for_taxon(@taxon, :map).should == [@mock_trusted]
#    end
#
#    it 'should NOT call #cached_images_for_taxon from #for_taxon if user wants to see unvetted stuff' do
#      @user.should_receive(:show_unvetted?).and_return(true)
#      DataObject.should_not_receive(:cached_images_for_taxon)
#      DataObject.should_receive(:find_by_sql).and_return([@User.gen
#      DataObject.for_taxon(@taxon, :image, :user => @user)
#    end
#
#    it 'should NOT call #cached_images_for_taxon from #for_taxon if user is admin' do
#      @user.should_receive(:is_admin?).and_return(true)
#      DataObject.should_not_receive(:cached_images_for_taxon)
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      DataObject.for_taxon(@taxon, :image, :user => @user)
#    end
#
#    it 'should NOT call #cached_images_for_taxon from #for_taxon if user is curator' do
#      @user.should_receive(:is_curator?).and_return(true)
#      DataObject.should_not_receive(:cached_images_for_taxon)
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      DataObject.for_taxon(@taxon, :image, :user => @user)
#    end
#
#    it 'should NOT call #cached_images_for_taxon from #for_taxon if agent is specified' do
#      mock_agent = Agent.gen
#      DataObject.should_not_receive(:cached_images_for_taxon)
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      DataObject.for_taxon(@taxon, :image, :agent => mock_agent)
#    end
#
#    it 'should call #cached_images_for_taxon from #for_taxon if nothing special is specified' do
#      DataObject.should_receive(:cached_images_for_taxon).and_return([@mock_trusted])
#      DataObject.for_taxon(@taxon, :image).should == [@mock_trusted]
#    end
#
#    it '#cached_images_for_taxon should NOT flag taxon for unvetted with trusted image' do
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      @taxon.should_not_receive(:includes_unvetted=)
#      DataObject.cached_images_for_taxon(@taxon).should == [@mock_trusted]
#    end
#
#    it '#cached_images_for_taxon should flag taxon for unvetted with unknown image' do
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted, @mock_unknown])
#      @taxon.should_receive(:includes_unvetted=).with(true)
#      DataObject.cached_images_for_taxon(@taxon).should == [@mock_trusted, @mock_unknown]
#    end
#
#    it '#cached_images_for_taxon should flag taxon for unvetted with untrusted image' do
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted, @mock_untrusted])
#      @taxon.should_receive(:includes_unvetted=).with(true)
#      DataObject.cached_images_for_taxon(@taxon).should == [@mock_trusted, @mock_untrusted]
#    end
#
#    it '#cached_images_for_taxon should collect hierarchy_entry ids from taxon' do
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      mock_he    = HierarchyEntry.gen
#      @taxon.should_receive(:hierarchy_entries).and_return([mock_he])
#      mock_he.should_receive(:id).and_return(16222828)
#      DataObject.cached_images_for_taxon(@taxon)
#    end
#
#    it 'should use image type ids' do
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      DataType.should_receive(:image_type_ids).and_return([1,2])
#      DataObject.cached_images_for_taxon(@taxon)
#    end
#
#    it '#cached_images_for_taxon should call the taxon id, of course' do
#      DataObject.should_receive(:find_by_sql).and_return([@mock_trusted])
#      @taxon.should_receive(:id).and_return(101)
#      DataObject.cached_images_for_taxon(@taxon)
#    end
#
#  end
#
#  describe '#build_query' do
#
#    before(:each) do
#      @taxon = TaxonConcept.gen
#      @user = User.gen
#      @agent = Agent.gen
#      # To avoid sub-function:
#      DataObject.stub!(:visibility_clause).and_return('whatever')
#    end
#
#    it 'should call #isibility_clause and add it to the query' do
#      DataObject.should_receive(:visibility_clause).and_return('test for this')
#      DataObject.build_query(@taxon, :image, {}).should match(/test for this/)
#    end
#
#    it 'should sort the way we want it to' do
#      DataObject.build_query(@taxon, :image, {}).should match(/ORDER BY dato\.published, dato\.vetted_id DESC, dato\.data_rating/)
#    end
#
#    it 'should NOT select on toc id when toc id is missing' do
#      DataObject.build_query(@taxon, :text, {}).should_not match(/AND toc\.id =/)
#    end
#
#    it 'should select on toc id when toc is specified' do
#      DataObject.build_query(@taxon, :text, :toc_id => 3).should match(/AND toc\.id = 3/)
#    end
#
#    it 'should NOT join in toc when type is NOT :text' do
#      DataObject.build_query(@taxon, :map, {}).should_not match(/JOIN data_objects_table_of_contents dotoc ON dotoc\.data_object_id = dato.id JOIN table_of_contents toc ON toc\.id = dotoc\.toc_id/)
#    end
#
#    it 'should join in toc when type is :text' do
#      DataObject.build_query(@taxon, :text, {}).should match(/JOIN data_objects_table_of_contents dotoc ON dotoc\.data_object_id = dato\.id JOIN table_of_contents toc ON toc\.id = dotoc\.toc_id/)
#    end
#
#    it 'should NOT join in agents_data_objects when an agent is NOT specified' do
#      DataObject.build_query(@taxon, :map, {}).should_not match(/JOIN agents_data_objects ado ON ado\.data_object_id = dato\.id/)
#    end
#
#    it 'should join in agents_data_objects when an agent is specified' do
#      DataObject.build_query(@taxon, :map, :agent => @agent).should match(/JOIN agents_data_objects ado ON ado\.data_object_id = dato\.id/)
#    end
#
#    it '#build_query should NOT add toc.* when type text toc_id is specified' do
#      DataObject.build_query(@taxon, :map, :toc_id => 1).should_not match(/toc\.\*/)
#    end
#
#    it '#build_query should NOT add toc.* when type is not text' do
#      DataObject.build_query(@taxon, :map, {}).should_not match(/toc\.\*/)
#    end
#
#    it '#build_query should add toc.* when type is text' do
#      DataObject.build_query(@taxon, :text, {}).should match(/toc\.\*/)
#    end
#
#  end
#
#  describe '#get_type_ids' do
#    it 'should delegate :map to DataType.map_type_ids' do
#      DataType.should_receive(:map_type_ids).and_return(:got_it)
#      DataObject.get_type_ids(:map).should == (:got_it)
#    end
#    it 'should delegate :text to DataType.text_type_ids' do
#      DataType.should_receive(:text_type_ids).and_return(:good)
#      DataObject.get_type_ids(:text).should == (:good)
#    end
#    it 'should delegate :video to DataType.video_type_ids' do
#      DataType.should_receive(:video_type_ids).and_return(:great)
#      DataObject.get_type_ids(:video).should == (:great)
#    end
#    it 'should delegate :image to DataType.image_type_ids' do
#      DataType.should_receive(:image_type_ids).and_return(:groovy)
#      DataObject.get_type_ids(:image).should == (:groovy)
#    end
#    it 'should raise an objection to any other type' do
#      lambda { DataObject.get_type_ids(:oops) }.should raise_error
#    end
#  end
#
#  describe '#visibility_clause' do
#
#    before(:each) do
#      @taxon = TaxonConcept.gen
#      @user = User.gen
#      @user.stub!(:show_unvetted?).and_return(false)
#      @user.stub!(:is_curator?).and_return(false)
#      @user.stub!(:can_curate?).and_return(false)
#      @user.stub!(:is_admin?).and_return(false)
#      @agent = Agent.gen
#      @preview_objects = ActiveRecord::Base.sanitize_sql(['OR (visibility_id = ? AND published IN (0,1)', Visibility.preview.id])
#    end
#
#    it 'should show tons of stuff to an admin' do
#      @user.should_receive(:is_admin?).and_return(true)
#      clause = DataObject.visibility_clause(:user => @user, :taxon => @taxon)
#      clause.should match(/visibility_id IN \(#{Visibility.all_ids.join('\s*,\s*')}\)/)
#      clause.should match(/#{@preview_objects.gsub(/\(/, '\\(').gsub(/\)/, '\\)')}/)
#    end
#
#    it 'should NOT add invisible when user can curate, but not for this taxon' do
#      @user.should_receive(:is_curator?).and_return(true)
#      @user.should_receive(:can_curate?).with(@taxon).and_return(false)
#      clause = DataObject.visibility_clause(:user => @user, :taxon => @taxon)
#      clause.should_not match(/visibility_id IN \(#{[Visibility.visible.id, Visibility.invisible.id].join('\s*,\s*')}\)/)
#    end
#
#    it 'should add invisible when user can curate taxon' do
#      @user.should_receive(:is_curator?).and_return(true)
#      @user.should_receive(:can_curate?).with(@taxon).and_return(true)
#      clause = DataObject.visibility_clause(:user => @user, :taxon => @taxon)
#      clause.should match(/visibility_id IN \(#{[Visibility.visible.id, Visibility.invisible.id].join('\s*,\s*')}\)/)
#    end
#
#    it 'should add unvetted stuff for users when show_unvetted? is specified' do
#      @user.should_receive(:show_unvetted?).and_return(true)
#      clause = DataObject.visibility_clause(:user => @user)
#      clause.should match(/vetted_id IN \(#{[Vetted.trusted.id, Vetted.untrusted.id, Vetted.unknown.id].join('\s*,\s*')}\)/)
#    end
#
#    it 'should add visibilities for users when show_unvetted? is specified' do
#      @user.should_receive(:show_unvetted?).and_return(true)
#      clause = DataObject.visibility_clause(:user => @user)
#      clause.should match(/vetted_id IN \(#{[Vetted.trusted.id, Vetted.untrusted.id, Vetted.unknown.id].join('\s*,\s*')}\)/)
#    end
#
#    it 'should do more if agent is specified' do
#      clause = DataObject.visibility_clause(:user => @user, :agent => @agent)
#      clause.should match(/vetted_id IN \(#{[Vetted.trusted.id, Vetted.untrusted.id, Vetted.unknown.id].join('\s*,\s*')}\)/)
#      clause.should match(/published IN \(1\)/)
#      clause.should match(/visibility_id IN \(#{[Visibility.visible.id, Visibility.invisible.id].join('\s*,\s*')}\)/)
#      clause.should match(/#{@preview_objects.gsub(/\(/, '\\(').gsub(/\)/, '\\)')}/)
#      clause.should match(/AND ado.agent_id = #{@agent.id}/)
#    end
#
#    it 'should have sensible defaults' do
#      clause = DataObject.visibility_clause(:user => @user)
#      clause.should match(/vetted_id IN \(#{Vetted.trusted.id}\)/)
#      clause.should match(/published IN \(1\)/)
#      clause.should match(/visibility_id IN \(#{Visibility.visible.id}\)/)
#    end
#
#  end
#
#  describe 'Agent-related methods:' do
#
#    before(:each) do
#      @dato   = DataObject.gen
#      @agent  = Agent.gen
#      @agent1 = Agent.gen
#      @agent2 = Agent.gen
#      @agent3 = Agent.gen
#      @author_id = 23 # doesn't really matter what it is
#      @source_id = 64 # doesn't really matter what it is
#      AgentRole.stub!(:author_id).at_least(1).times.and_return(@author_id)
#      AgentRole.stub!(:source_id).at_least(1).times.and_return(@source_id)
#      @ado1   = AgentsDataObject.gen(:agent_role_id => @author_id, :agent => @agent1, :data_object => @dato)
#      @ado2   = AgentsDataObject.gen(:agent_role_id => @author_id, :agent => @agent2, :data_object => @dato)
#      @ado3   = AgentsDataObject.gen(:agent_role_id => @author_id, :agent => @agent3, :data_object => @dato)
#      @ado_a  = AgentsDataObject.gen(:agent_role_id => @source_id, :agent => @agent3, :data_object => @dato)
#      @ado_b  = AgentsDataObject.gen(:agent_role_id => @source_id, :agent => @agent2, :data_object => @dato)
#      @ado_c  = AgentsDataObject.gen(:agent_role_id => @source_id, :agent => @agent1, :data_object => @dato)
#    end
#
#    it '#fake_author should be called multiple time and remeber each one' do
#      Agent.should_receive(:new).with(:test_options).and_return(:test_agent)
#      Agent.should_receive(:new).with(:more_options).and_return(:another_agent)
#      @dato.fake_author(:test_options).should == [:test_agent]
#      @dato.fake_author(:more_options).should == [:test_agent, :another_agent]
#    end
#
#    it '#authors should return a list of agents' do
#      @dato.authors.should == [@agent1, @agent2, @agent3]
#    end
#
#    it '#authors should handle null agents' do
#      @ado2.should_receive(:agent).and_return(nil)
#      @dato.authors.should == [@agent1, @agent3]
#    end
#
#    it '#authors should add fake authors to #agents' do
#      Agent.should_receive(:new).with(:test_options).and_return(@agent)
#      @dato.fake_author(:test_options)
#      @dato.authors.should == [@agent1, @agent2, @agent3, @agent]
#    end
#
#    it '#sources should return a list of agents' do
#      @dato.sources.should == [@agent3, @agent2, @agent1]
#    end
#
#    it '#sources should handle null agents' do
#      @ado_b.should_receive(:agent).and_return(nil)
#      @dato.sources.should == [@agent3, @agent1]
#    end
#
#    it '#sources should resort to authors when empty' do
#      AgentsDataObject.delete_all(:agent_role_id => @source_id)
#      @dato.sources.should == [@agent1, @agent2, @agent3] # This comes from the authors, now.
#    end
#
#  end
#
#  describe '#is_curatable_by?' do
#
#    before(:each) do
#      @user    = User.gen
#      @dato    = DataObject.gen
#      @mock_he = HierarchyEntry.gen
#    end
#
#    it 'should be curatable by a user with access' do
#      @dato.should_receive(:hierarchy_entries).and_return([@mock_he])
#      @user.should_receive(:can_curate?).and_return(true)
#      @dato.is_curatable_by?(@user).should == true
#    end
#
#    it 'should NOT be curatable by a user WITHOUT access' do
#      @dato.should_receive(:hierarchy_entries).and_return([@mock_he])
#      @user.should_receive(:can_curate?).and_return(false)
#      @dato.is_curatable_by?(@user).should == false
#    end
#
#  end
#
#  describe '#taxon_concepts' do
#
#    it 'should get all taxon_concepts that a data object is associated with' do
#      data_objects(:many_taxa).taxon_concepts.collect {|tc| tc.id }.should ==
#        [taxon_concepts(:Archaea).id, taxon_concepts(:Fungi).id, taxon_concepts(:Plantae).id]
#    end
#
#  end
#
#  describe '#hierarchy_entries' do
#
#    it 'should get all hierarchy_entries that a data object is associated with' do
#      # hierarchy_entries.yml (the fixture) is auto-generated, so I don't want to trust the names:
#      he_s = [taxon_concepts(:Archaea), taxon_concepts(:Fungi), taxon_concepts(:Plantae)].collect {|tc| tc.hierarchy_entries}.flatten
#      data_objects(:many_taxa).hierarchy_entries.collect {|he| he.id }.should == he_s.collect {|he| he.id}.uniq
#    end
#
#  end

end
