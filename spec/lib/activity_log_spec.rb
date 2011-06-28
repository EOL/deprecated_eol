require File.dirname(__FILE__) + '/../spec_helper'

describe EOL::ActivityLog do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    # A curator is the only thing who's activity log would actually involve ALL the types:
    @curator = @testy[:curator]
    Comment.gen(:user_id => @curator.id, :created_at => 6.seconds.ago) # implies comment activity
    dato = DataObject.gen(:created_at => 5.seconds.ago)
    UsersDataObject.gen(:user_id => @curator.id, :data_object => dato) # implies created text object activity
    CuratorActivityLog.gen(:user_id => @curator.id, :activity => Activity.trusted, :created_at => 4.seconds.ago)
    CollectionActivityLog.gen(:user_id => @curator.id, :activity => Activity.create, :created_at => 3.seconds.ago)
    CommunityActivityLog.gen(:user_id => @curator.id, :activity => Activity.create, :created_at => 2.seconds.ago)
  end

  it 'should be empty by default' do
    user = User.gen
    user.activity_log.empty?.should be_true
  end

  it 'should list all activity_log items for a user, sorted by time' do
    @curator.activity_log[-5].class.should == Comment
    @curator.activity_log[-4].class.should == UsersDataObject
    @curator.activity_log[-3].class.should == CuratorActivityLog
    @curator.activity_log[-2].class.should == CollectionActivityLog
    @curator.activity_log[-1].class.should == CommunityActivityLog
  end

  it 'should work with Community comments, focus list activity, and community activity' do
    community = Community.gen
    Comment.gen(:parent => community, :created_at => 4.seconds.ago)
    # This proves that any activity logged on the focus list of the community is something that shows up in the
    # community feed itself (rather than having to look at the focus list directly).  For example, if someone adds
    # something to the community's focus list, we expect to see that in the activity log of the community itself.
    CollectionActivityLog.gen(:collection => community.focus, :created_at => 3.seconds.ago)
    CommunityActivityLog.gen(:community => community, :created_at => 2.seconds.ago)
    community.activity_log.length.should == 3
    community.activity_log[-3].class.should == Comment
    community.activity_log[-2].class.should == CollectionActivityLog
    community.activity_log[-1].class.should == CommunityActivityLog
  end

  it 'should work with DataObject' do
    dato = DataObject.gen(:created_at => 5.seconds.ago)
    UsersDataObject.gen(:data_object => dato)
    Comment.gen(:parent => dato, :created_at => 4.seconds.ago)
    CuratorActivityLog.gen(:changeable_object_type_id => ChangeableObjectType.data_object.id,
                           :object_id => dato, :created_at => 3.seconds.ago)
  end

  # TODO - Ideally, this would actually create a bunch of data objects related to the taxon concept in various ways.
  # ...But that's a lot of work, so we're skipping it for now.  Thus, it assumes that TaxonConcept#all_data_objects
  # works as intended. ...Alternatively, we could stub! the all_data_objects method and force it to "work".
  it 'should work with TaxonConcept' do
    Comment.gen(:parent => @testy[:taxon_concept], :created_at => 5.seconds.ago)
    Comment.gen(:parent => @testy[:taxon_concept].images.first, :created_at => 4.seconds.ago)
    # Also Comments on the children of this taxon concept
    Comment.gen(:parent => @testy[:child1], :created_at => 3.seconds.ago)

    dato = DataObject.gen(:created_at => 2.seconds.ago)
    # We also want to see comments on data objects on the page
    UsersDataObject.gen(:taxon_concept_id => @testy[:id], :data_object => dato)
    # We're curating one of the images, but we CANNOT force the date from here... so we're going to make this last on
    # the list.
    @testy[:taxon_concept].images.first.curate_association(@curator,
                                                           @testy[:taxon_concept].entry,
                                                           :vetted_id => Vetted.trusted.id,
                                                           :curate_vetted_status => true)

    @testy[:taxon_concept].activity_log[-5].class.should == Comment
    @testy[:taxon_concept].activity_log[-5].parent_id.should == @testy[:id]
    @testy[:taxon_concept].activity_log[-4].class.should == Comment
    @testy[:taxon_concept].activity_log[-4].parent_id.should == @testy[:taxon_concept].images.first.id
    @testy[:taxon_concept].activity_log[-3].class.should == Comment
    @testy[:taxon_concept].activity_log[-3].parent_id.should == @testy[:child1].id
    @testy[:taxon_concept].activity_log[-2].class.should == UsersDataObject
    @testy[:taxon_concept].activity_log[-1].class.should == CuratorActivityLog
  end

end
