require "spec_helper"

describe Community do

  before(:all) do
    @name = "valid community name"
    @description = "Valid description"
    load_foundation_cache # Needs data_type info.
  end

  it 'should validate the name' do
    c = Community.new(name: '', description: @description)
    c.valid?.should_not be_true
    c = Community.new(name: 'x'*129, description: @description)
    c.valid?.should_not be_true
    c = Community.gen(name: 'already there')
    c.valid?.should be_true
    c = Community.new(name: 'already there', description: @description)
    c.valid?.should_not be_true
  end

  it 'should be able to add a member' do
    c = Community.gen
    c.members.should be_blank
    u = User.gen
    u.is_member_of?(c).should be_false
    c.add_member(u)
    u.is_member_of?(c).should be_true
  end

  it "should create a new instance given valid attributes" do
    count = Community.count
    c = Community.create!(name: @name, description: @description)
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

  it 'should have an activity log' do
    community = Community.gen
    community.respond_to?(:activity_log).should be_true
    community.activity_log.should be_a WillPaginate::Collection
  end

end
