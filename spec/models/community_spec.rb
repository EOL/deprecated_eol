require 'spec_helper'

describe Community do

  before(:each) do
    @name = "valid community name"
    @description = "Valid description"
  end

  it "should create a new instance given valid attributes" do
    count = Community.count
    Community.create!(:name => @name, :description => @description)
    Community.count.should == count + 1
    Community.last.name.should == @name
    Community.last.description.should == @description
  end

  it 'should be able to add a member' do
    community = Community.gen
    community.members.should be_blank
    user = User.gen
    community.add_member(user)
    community.members.map {|m| m.user_id}.should include(user.id)
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

end
