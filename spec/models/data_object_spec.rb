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

    @dato = DataObject.gen(:description => 'That <b>description has unclosed <i>html tags')
    DataObjectsTaxonConcept.gen(:taxon_concept_id => @taxon_concept.id, :data_object_id => @dato.id)
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild

    @hierarchy_entry = HierarchyEntry.gen
    @image_dato      = @taxon_concept.images_from_solr(100).last

    @big_int = 20081014234567
    @image_cache_path = %r/2008\/10\/14\/23\/4567/
    content_server_match = $CONTENT_SERVERS[0] + $CONTENT_SERVER_CONTENT_PATH
    content_server_match.gsub!(/\d+/, '\\d+') # Because we don't care *which* server it hits...
    @content_server_match = %r/#{content_server_match}/
    @flash_dato = DataObject.gen(:data_type => DataType.find_by_translated(:label, 'flash'), :object_cache_url => @big_int)

    # add user submitted text
    @user = User.gen
    @user_submitted_text = @taxon_concept.add_user_submitted_text(:user => @user)
  end

  it 'should be able to replace wikipedia articles' do
    TocItem.gen_if_not_exists(:label => 'wikipedia')

    published_do = build_data_object('Text', 'This is a test wikipedia article content', :published => 1, :vetted => Vetted.trusted, :visibility => Visibility.visible)
    DataObjectsTaxonConcept.gen(:taxon_concept_id => @taxon_concept.id, :data_object_id => published_do.id)
    published_do.toc_items << TocItem.wikipedia
    published_do_association = published_do.association_with_exact_or_best_vetted_status(@taxon_concept)

    preview_do = build_data_object('Text', 'This is a test wikipedia article content', :guid => published_do.guid,
                                   :published => 1, :vetted => Vetted.unknown, :visibility => Visibility.preview)
    DataObjectsTaxonConcept.gen(:taxon_concept_id => @taxon_concept.id, :data_object_id => preview_do.id)
    preview_do.toc_items << TocItem.wikipedia
    preview_do_association = preview_do.association_with_exact_or_best_vetted_status(@taxon_concept)

    published_do.published.should be_true
    # ...This one is failing, but it's quite complicated, so I'm coming back to it:
    preview_do_association.visibility.should == Visibility.preview
    preview_do_association.vetted.should == Vetted.unknown

    preview_do.publish_wikipedia_article(@taxon_concept)
    published_do.reindex
    preview_do.reindex

    published_do.published.should_not be_true
    preview_do.published.should be_true

    published_do_association.vetted.should == Vetted.trusted
    published_do_association.visibility.should == Visibility.visible
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
   text_dato  = build_data_object('Text', 'some description', :toc_item => TocItem.wikipedia)
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

 it 'ratings should verify uniqueness of pair guid/user in users_data_objects_ratings' do
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
    map_dato = DataObject.gen(:data_type => DataType.map)
    image_dato = DataObject.gen(:data_type => DataType.image)
    image_map_dato = DataObject.gen(:data_type => DataType.image, :data_subtype => DataType.map)
    map_dato.map?.should be_true
    map_dato.image_map?.should be_false
    image_dato.image_map?.should be_false
    image_dato.image?.should be_true
    image_map_dato.image_map?.should be_true
    image_map_dato.image?.should be_true
    image_map_dato.map?.should be_false
  end

  it 'should return true if this is an image' do
    dato = DataObject.gen(:data_type_id => DataType.image_type_ids.first)
    dato.image?.should be_true
  end

  it 'should return false if this is NOT an image' do
    dato = DataObject.gen(:data_type_id => DataType.image_type_ids.sort.last + 1) # Clever girl...
    dato.image?.should_not be_true
  end

  it 'should return true if this is a link' do
    dato = DataObject.gen(:data_type_id => DataType.text_type_ids.first, :data_subtype_id => DataType.link_type_ids.first, :source_url => "http://eol.org")
    dato.link?.should be_true
  end

  it 'should return false if this is NOT a link' do
    dato = DataObject.gen(:data_type_id => DataType.text_type_ids.first, :data_subtype_id => DataType.link_type_ids.sort.last + 1, :source_url => "http://eol.org")
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

  # 'Gofas, S.; Le Renard, J.; Bouchet, P. (2001). Mollusca, <B><I>in</I></B>: Costello, M.J. <i>et al.</i> (Ed.) (2001). <i>European register of marine species: a check-list of the marine species in Europe and a bibliography of guides to their identification.'

  it 'should close tags in data_objects (incl. users)' do
    dato_descr_before = @dato.description
    dato_descr_after  = @dato.description.balance_tags

    dato_descr_after.should == 'That <b>description has unclosed <i>html tags</i></b>'
  end

  it 'should close tags in references' do
    full_ref         = 'a <b>b</div></HTML><i'
    repaired_ref     = '<div>a <b>b</div></HTML><i</b>'

    @dato.refs << ref = Ref.gen(:full_reference => full_ref, :published => 1, :visibility => Visibility.visible)
    ref_after = @dato.visible_references[0].full_reference.balance_tags
    ref_after.should == repaired_ref
  end

  it 'should delegate #image_cache_path to ContentServer' do
    ContentServer.should_receive(:cache_path).with(:foo, nil).and_return("worked")
    DataObject.image_cache_path(:foo, :large).should == "worked_large.#{$SPECIES_IMAGE_FORMAT}"
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
    dato.short_title.length.should <= 34
    dato.short_title.should =~ /\.\.\.$/
  end

  # TODO - ideally, this should be something like "Image of Procyon lotor", but that would be a LOT of work to extract
  # froom the data_objects/show view (mainly because it builds links).
  it 'should resort to the data type, if there is no description' do
    dato = DataObject.gen(:object_title => '', :description => '', :data_type => DataType.image)
    dato.short_title.should == "Image"
  end

  it 'should update the Solr record when the object is curated' do
    solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
    solr_connection.delete_all_documents
    solr_connection.get_results("data_type_id:#{DataType.text.id}")['numFound'].should == 0
    @user_submitted_text = @taxon_concept.add_user_submitted_text(:user => @user)
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
    cdohe_count = CuratedDataObjectsHierarchyEntry.count(:conditions => "hierarchy_entry_id = #{@hierarchy_entry.id}")
    @image_dato.remove_curated_association(@curator, @hierarchy_entry)
    CuratedDataObjectsHierarchyEntry.count(:conditions => "hierarchy_entry_id = #{@hierarchy_entry.id}").should ==
        cdohe_count - 1
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
    cdohe.should == nil
  end

  it '#untrust_reasons should return the same untrust reasons for all versions of the data object' do
    CuratedDataObjectsHierarchyEntry.delete_all
    @image_dato = DataObject.find(@image_dato)
    @image_dato.add_curated_association(@curator, @hierarchy_entry)
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
    cdohe.vetted_id = Vetted.untrusted.id
    cdohe.visibility_id = Visibility.invisible.id
    cal = CuratorActivityLog.gen(:target_id => @image_dato.id,
                              :changeable_object_type_id => ChangeableObjectType.curated_data_objects_hierarchy_entry.id,
                              :activity_id => Activity.untrusted.id,
                              :hierarchy_entry_id => @hierarchy_entry.id,
                              :data_object_guid => @image_dato.guid,
                              :user_id => @curator.id,
                              :created_at => 0.seconds.from_now)
    CuratorActivityLogsUntrustReason.create(:curator_activity_log_id => cal.id, :untrust_reason_id => UntrustReason.misidentified.id)
    @image_dato = DataObject.find(@image_dato)
    @image_dato.untrust_reasons(@image_dato.all_associations.last).should == [UntrustReason.misidentified.id]
    new_image_dato = DataObject.gen(:guid => @image_dato.guid, :created_at => Time.now)
    new_image_dato.untrust_reasons(new_image_dato.all_associations.last).should == [UntrustReason.misidentified.id]
  end
  
  it '#hide_reasons should return the same hide reasons for all versions of the data object' do
    CuratedDataObjectsHierarchyEntry.delete_all
    @image_dato = DataObject.find(@image_dato)
    @image_dato.add_curated_association(@curator, @hierarchy_entry)
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_hierarchy_entry_id_and_data_object_id(@hierarchy_entry.id,
                                                                                           @image_dato.id)
    cdohe.vetted_id = Vetted.unknown.id
    cdohe.visibility_id = Visibility.invisible.id
    cal = CuratorActivityLog.gen(:target_id => @image_dato.id,
                              :changeable_object_type_id => ChangeableObjectType.curated_data_objects_hierarchy_entry.id,
                              :activity_id => Activity.hide.id,
                              :hierarchy_entry_id => @hierarchy_entry.id,
                              :data_object_guid => @image_dato.guid,
                              :user_id => @curator.id,
                              :created_at => 0.seconds.from_now)
    CuratorActivityLogsUntrustReason.create(:curator_activity_log_id => cal.id, :untrust_reason_id => UntrustReason.poor.id)
    @image_dato = DataObject.find(@image_dato)
    @image_dato.hide_reasons(@image_dato.all_associations.last).should == [UntrustReason.poor.id]
    new_image_dato = DataObject.gen(:guid => @image_dato.guid, :created_at => Time.now)
    new_image_dato.hide_reasons(new_image_dato.all_associations.last).should == [UntrustReason.poor.id]
  end

  it '#published_entries should read data_objects_hierarchy_entries'

  it '#published_entries should have a user_id on hierarchy entries that were added by curators'

  it '#all_associations should return all associations for the data object' do
    all_associations_count_for_udo = @user_submitted_text.all_associations.count
    CuratedDataObjectsHierarchyEntry.find_or_create_by_hierarchy_entry_id_and_data_object_id( @hierarchy_entry.id,
        @user_submitted_text.id, :data_object_guid => @user_submitted_text.guid, :vetted => Vetted.trusted,
        :visibility => Visibility.visible, :user => @curator)
    DataObject.find(@user_submitted_text).all_associations.count.should == all_associations_count_for_udo + 1
  end

  it '#safe_rating should NOT re-calculate ratings that are in the normal range.' do
    dato = DataObject.gen(:data_rating => 1.2)
    dato.safe_rating.should == 1.2
  end

  it '#safe_rating should re-calculate really low ratings' do
    dato = DataObject.gen(:data_rating => 0.2)
    dato.should_receive(:recalculate_rating).and_return(1.2)
    dato.safe_rating.should == 1.2
  end

  it '#safe_rating should return the minimum rating if the rating is calculated as lower than the minimum rating' do
    dato = DataObject.gen(:data_rating => 0.2)
    dato.should_receive(:recalculate_rating).and_return(0.2)
    dato.safe_rating.should == DataObject.minimum_rating
  end

  it '#safe_rating should re-calculate really high ratings' do
    dato = DataObject.gen(:data_rating => 5.2)
    dato.should_receive(:recalculate_rating).and_return(1.2)
    dato.safe_rating.should == 1.2
  end

  it '#safe_rating should return the maximum rating if the rating is calculated as higher than the maximum' do
    dato = DataObject.gen(:data_rating => 5.2)
    dato.should_receive(:recalculate_rating).and_return(5.2)
    dato.safe_rating.should == DataObject.maximum_rating
  end

  it 'should get remote image if object is pre-defined to be hosted remotely' do
    cp = ContentPartner.gen(:full_name => "Discover Life")
    resource = Resource.gen(:content_partner_id => cp.id)
    harvest = HarvestEvent.gen(:resource_id => resource.id)
    dato = DataObject.gen(:object_title => 'xxx Discover Life: Point Map of Gadus morhua yyy', 
                          :data_type_id => DataType.image.id,
                          :object_cache_url => '200810061224383',
                          :object_url => 'http://my.object.url',
                          :data_subtype_id => DataType.map.id)
    dohe = DataObjectsHarvestEvent.gen(:data_object_id => dato.id, :harvest_event_id => harvest.id)
    dato.access_image_from_remote_server?('580_360').should == true
    dato.access_image_from_remote_server?('260_190').should == false
    dato.access_image_from_remote_server?(:orig).should == true
  end

  it '#create_user_text should add rights holder only if rights holder not provided, license is not public domain and if it is not a link object' do
    params = { :data_type_id => DataType.text.id.to_s,
               :license_id => License.public_domain.id.to_s,
               :object_title => "",
               :bibliographic_citation => "",
               :source_url => "",
               :rights_statement => "",
               :description => "",
               :language_id => Language.english.id.to_s,
               :rights_holder => ""}
    options = { :taxon_concept => TaxonConcept.first,
                :user => User.first,
                :toc_id => [TocItem.first.id.to_s],
                :link_object => false }
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
    dato.link?.should == true
    dato.rights_holder.should == ''
  end

  it '#create_user_text should add proper vetted and visibility statuses to the created link object' do
    assistant_curator = build_curator(@taxon_concept, :level=>:assistant)
    full_curator = build_curator(@taxon_concept, :level=>:full)
    master_curator = build_curator(@taxon_concept, :level=>:master)
    admin = User.gen(:admin=>1)
    params = { :data_type_id => DataType.text.id.to_s,
               :license_id => nil,
               :object_title => "",
               :bibliographic_citation => "",
               :source_url => "http://eol.org",
               :rights_statement => "",
               :description => "This is link description",
               :language_id => Language.english.id.to_s,
               :rights_holder => ""}
    options = { :taxon_concept => TaxonConcept.first,
                :toc_id => [TocItem.first.id.to_s],
                :link_object => true }
    options[:user] = @user
    dato = DataObject.create_user_text(params, options)
    dato.link?.should == true
    dato.users_data_object.vetted_id.should == Vetted.untrusted.id
    dato.users_data_object.visibility_id.should == Visibility.invisible.id
    options[:user] = assistant_curator
    dato = DataObject.create_user_text(params, options)
    dato.link?.should == true
    dato.users_data_object.vetted_id.should == Vetted.unknown.id
    dato.users_data_object.visibility_id.should == Visibility.visible.id
    options[:user] = full_curator
    dato = DataObject.create_user_text(params, options)
    dato.link?.should == true
    dato.users_data_object.vetted_id.should == Vetted.trusted.id
    dato.users_data_object.visibility_id.should == Visibility.visible.id
    options[:user] = master_curator
    dato = DataObject.create_user_text(params, options)
    dato.link?.should == true
    dato.users_data_object.vetted_id.should == Vetted.trusted.id
    dato.users_data_object.visibility_id.should == Visibility.visible.id
    options[:user] = admin
    dato = DataObject.create_user_text(params, options)
    dato.link?.should == true
    dato.users_data_object.vetted_id.should == Vetted.trusted.id
    dato.users_data_object.visibility_id.should == Visibility.visible.id
  end

  it '#create_user_text should call reload on TaxonConcept, even when fails' do
    new_text_params = {
      :data_type_id => DataType.text.id.to_s,
      :license_id => nil,
      :license_id => License.cc.id.to_s,
      :object_title => "",
      :bibliographic_citation => "",
      :source_url => "http://eol.org",
      :rights_statement => "",
      :description => "This is link description",
      :language_id => Language.english.id.to_s,
      :rights_holder => ""
    }
    lambda {
      @taxon_concept.should_receive(:reload).and_return(true)
      DataObject.create_user_text(new_text_params, :user => @user, :taxon_concept => @taxon_concept)
    }.should raise_error
  end

  it '#latest_published_version_in_same_language should not return itself if the object is unpublished' do
    d = DataObject.gen(:published => 1)
    d.latest_published_version_in_same_language.should == d
    d = DataObject.gen(:published => 0)
    d.latest_published_version_in_same_language.should == nil
  end

end

