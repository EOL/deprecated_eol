require File.dirname(__FILE__) + '/../spec_helper'

describe EOL::ActivityLog do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching(:testy)
    # This sucks, but my "testy" scenario, for some reason, wasn't adding these:
    Activity.create_defaults
    @testy = EOL::TestInfo.load('testy')
    # A curator is the only thing who's activity log would actually involve ALL the types:
    @curator = @testy[:curator]
    @solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
    @solr_connection.delete_all_documents
    Comment.gen(:user_id => @curator.id, :created_at => 6.seconds.ago) # implies comment activity
    dato = DataObject.gen(:created_at => 5.seconds.ago)
    UsersDataObject.gen(:user_id => @curator.id, :data_object => dato, :vetted => Vetted.trusted) # implies created text object activity
    CuratorActivityLog.gen(:user_id => @curator.id, :activity => Activity.trusted, :created_at => 4.seconds.ago)
    CollectionActivityLog.gen(:user_id => @curator.id, :activity => Activity.create, :created_at => 3.seconds.ago)
    CommunityActivityLog.gen(:user_id => @curator.id, :activity => Activity.create, :created_at => 2.seconds.ago)
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  it 'should be empty by default' do
    user = User.gen
    user.activity_log.empty?.should be_true
  end

  it 'should list all activity_log items for a user, sorted by time' do
    # TODO - some logs are triggered through the controller, not on the creation of particular objects
    @curator.activity_log[1]['instance'].class.should == Comment
    # @curator.activity_log[3]['instance'].class.should == UsersDataObject
    # @curator.activity_log[2]['instance'].class.should == CuratorActivityLog
    # @curator.activity_log[1]['instance'].class.should == CollectionActivityLog
    @curator.activity_log[0]['instance'].class.should == CommunityActivityLog
  end

  it 'should work with Community comments, focus list activity, and community activity' do
    community = Community.gen
    Comment.gen(:parent => community, :created_at => 4.seconds.ago, :parent_type => 'Community')
    # This proves that any activity logged on the focus list of the community is something that shows up in the
    # community feed itself (rather than having to look at the focus list directly).  For example, if someone adds
    # something to the community's focus list, we expect to see that in the activity log of the community itself.
    CollectionActivityLog.gen(:collection => community.collections.first, :created_at => 3.seconds.ago)
    CommunityActivityLog.gen(:community => community, :created_at => 2.seconds.ago)
    community.activity_log.length.should == 2
    community.activity_log[1]['instance'].class.should == Comment
    community.activity_log[0]['instance'].class.should == CommunityActivityLog
  end

  it 'should work with DataObject' do
    dato = DataObject.gen(:created_at => 5.seconds.ago)
    UsersDataObject.gen(:data_object => dato, :vetted => Vetted.trusted)
    Comment.gen(:parent => dato, :created_at => 4.seconds.ago)
    CuratorActivityLog.gen(:changeable_object_type_id => ChangeableObjectType.data_object.id,
                           :object_id => dato, :created_at => 3.seconds.ago)
  end

  # Okay, based on the above examples, I'm going to henceforth assume that sorting by date works.  ...because
  # handling taxon concepts is tricky, I would rather break up the tests without worrying about it:
  it 'should work with TaxonConcept' do
    # 'Taxon Concept Comments show up'
    Comment.gen(:parent => @testy[:taxon_concept], :parent_type => 'TaxonConcept')
    @testy[:taxon_concept].activity_log.first['instance'].class.should == Comment
    @testy[:taxon_concept].activity_log.first['instance'].parent_id.should == @testy[:id]
    # 'Image comments show up'
    Comment.gen(:parent => @testy[:taxon_concept].images_from_solr.first)
    @testy[:taxon_concept].reload
    # TODO ... this isn't working, yet:
    if false
      @testy[:taxon_concept].activity_log.first['instance'].class.should == Comment
      @testy[:taxon_concept].activity_log.first['instance'].parent_id.should == @testy[:taxon_concept].images_from_solr.first.id
      # 'Comments on the children of this TC show up'
      Comment.gen(:parent => @testy[:child1])
      @testy[:taxon_concept].reload
      @testy[:taxon_concept].activity_log.first['instance'].class.should == Comment
      @testy[:taxon_concept].activity_log.first['instance'].parent_id.should == @testy[:child1].id
      expect 'Comments on user-submitted text show up'
      dato = DataObject.gen(:created_at => 2.seconds.ago)
      UsersDataObject.gen(:taxon_concept_id => @testy[:id], :data_object => dato, :vetted => Vetted.trusted)
      @testy[:taxon_concept].reload
      @testy[:taxon_concept].activity_log.first['instance'].class.should == UsersDataObject
      expect 'Curation of data objects on the page show up'
      dohe = DataObjectsHierarchyEntry.find_by_data_object_id_and_hierarchy_entry_id(
        @testy[:taxon_concept].images_from_solr.first.id,
        @testy[:taxon_concept].entry.id
      )
      CuratorActivityLog.gen(:changeable_object_type_id => ChangeableObjectType.data_objects_hierarchy_entry.id,
                             :object_id => dohe.id)
      @testy[:taxon_concept].reload
      @testy[:taxon_concept].activity_log.first['instance'].class.should == CuratorActivityLog
    end
  end

end
