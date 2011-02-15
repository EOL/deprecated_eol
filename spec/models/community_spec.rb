require 'spec_helper'

describe Community do

  before(:all) do
    @name = "valid community name"
    @description = "Valid description"
    SpecialCollection.create_all
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
    Community.special.should be_nil
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

end
