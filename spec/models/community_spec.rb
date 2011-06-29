require 'spec_helper'

describe Community do

  before(:all) do
    @name = "valid community name"
    @description = "Valid description"
    SpecialCollection.create_all
    load_foundation_cache # Needs data_type info.
  end

  it 'should validate the name' do
    c = Community.new(:name => '', :description => @description)
    c.valid?.should_not be_true
    c = Community.new(:name => 'x'*129, :description => @description)
    c.valid?.should_not be_true
    c = Community.gen(:name => 'already there')
    c.valid?.should be_true
    c = Community.new(:name => 'already there', :description => @description)
    c.valid?.should_not be_true
  end

  it 'should find the special community' do
    sp = Community.find_by_name($SPECIAL_COMMUNITY_NAME)
    sp ||= Community.gen(:name => $SPECIAL_COMMUNITY_NAME)
  end

  it 'should be #special?' do
    c = Community.gen(:show_special_privileges => 1)
    c.special?.should be_true
  end

  it 'should be able to add default roles to itself' do
    c = Community.gen
    Role.should_receive(:add_defaults_to_community).with(c)
    c.add_default_roles
  end

  it 'should be able to add a member' do
    c = Community.gen
    c.members.should be_blank
    u = User.gen
    u.member_of?(c).should be_false
    c.add_member(u)
    u.member_of?(c).should be_true
  end

  it 'should be able to create the special community' do
    Community.delete_all(:name => $SPECIAL_COMMUNITY_NAME)
    lambda { Community.special }.should raise_error
    Community.create_special
    Community.special.should_not be_nil
    Community.special.name.should == $SPECIAL_COMMUNITY_NAME
    Community.special.roles.should_not be_blank
  end

  it "should create a new instance given valid attributes" do
    count = Community.count
    c = Community.create!(:name => @name, :description => @description)
    Community.count.should == count + 1
    Community.last.name.should == @name
    Community.last.description.should == @description
    c.valid?.should be_true
  end

  it 'should be able to answer has_member?' do
    community = Community.gen
    community.members.should be_blank
    user = User.gen
    another_user = User.gen
    community.add_member(user)
    community.has_member?(user).should be_true
    community.has_member?(another_user).should_not be_true
  end

  it 'should be able to remove a member' do
    community = Community.gen
    user = User.gen
    community.add_member(user)
    community.has_member?(user).should be_true
    community.remove_member(user)
    community.has_member?(user).should_not be_true
  end

  it 'should have a #focus named "{name}\'s Focus"' do
    community = Community.gen(:name => 'Bob')
    community.focus.should_not be_nil
    community.focus.name.should == "Bob's Focus"
  end

  it 'should have an activity log' do
    community = Community.gen
    community.respond_to?(:activity_log).should be_true
    community.activity_log.should be_a EOL::ActivityLog
  end

  it 'should post a notification to the feed when a user joins the community' do
    user = User.gen
    community = Community.gen
    community.add_member(user)
    # TODO - ActivityLog
  end

  it 'should post a notification to the feed when a user leaves the community' do
    user = User.gen
    community = Community.gen
    community.add_member(user)
    community.remove_member(user)
    # TODO - ActivityLog
  end

  it 'should post a note to the feed when a member is granted a role' do
    user = User.gen
    community = Community.gen
    member = community.add_member(user)
    role = Role.gen(:community => community)
    member.add_role role
    community.reload
    # TODO - ActivityLog
  end

  it 'should post a note to the feed when a taxon Concept is added to the focus list' do
    community = Community.gen
    tc = TaxonConcept.gen
    tc.stub!(:scientific_name).and_return('Our TC')
    community.focus.add tc
    # TODO - ActivityLog
  end

  it 'should post a note to the feed when an image is added to the focus list' do
    community = Community.gen
    dato = DataObject.gen(:data_type => DataType.image)
    community.focus.add dato
    # TODO - ActivityLog
  end

  it 'should post a note to the feed when a Collection is added to the focus list' do
    community = Community.gen
    watching = Collection.gen
    community.focus.add watching
    # TODO - ActivityLog
  end

  it 'should post a note to the feed when a Community is added to the focus list' do
    community = Community.gen
    watching = Community.gen
    community.focus.add watching
    # TODO - ActivityLog
  end

  it 'should post a note to the feed when a user is added to the focus list' do
    community = Community.gen
    user = User.gen
    community.focus.add user
    # TODO - ActivityLog
  end

end
