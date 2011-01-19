require 'spec_helper'

describe Privilege do

  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :sym => "value for sym",
      :level => 1,
      :type => "value for type"
    }
  end

  it "should create a new instance given valid attributes" do
    Privilege.create!(@valid_attributes)
  end

  it 'should be invalid if the name is not unique' do
    Privilege.gen(:name => @valid_attributes[:name])
    p = Privilege.new(@valid_attributes)
    p.valid?.should_not be_true
  end

  it 'should list all non-special privileges for a non-special community, sorted by name' do
    c = Community.gen
    Privilege.delete_all
    privs = []
    3.times { privs << Privilege.gen }
    Privilege.gen(:special => true)
    Privilege.all_for_community(c).map {|p| p.name}.sort.should == privs.map {|p| p.name}.sort
  end

  it 'should list *all* privileges for special communities (sorted by name)' do
    c = Community.gen(:show_special_privileges => true)
    return_val = [Privilege.gen, Privilege.gen].sort_by {|p| p.name}
    Privilege.should_receive(:all).and_return return_val
    Privilege.all_for_community(c).should == return_val
  end

  it 'should use #cached_find if sent a method known by KnownPrivileges' do
    KnownPrivileges.should_receive(:symbols).and_return [:known]
    Privilege.should_receive(:cached_find).with(:sym, 'known').and_return(true)
    Privilege.known.should be_true
  end

  it 'should know about all member-editing privileges' do
    KnownPrivileges.create_all
    member_editing = Privilege.member_editing_privileges
    member_editing.include?(Privilege.grant_level_20_privileges).should be_true
    member_editing.include?(Privilege.revoke_level_20_privileges).should be_true
    member_editing.include?(Privilege.grant_level_10_privileges).should be_true
    member_editing.include?(Privilege.revoke_level_10_privileges).should be_true
  end

  it 'none of the member editing privilieges should be nil' do
    KnownPrivileges.create_all
    Privilege.member_editing_privileges.each do |p|
      p.should_not be_nil
    end
  end

end
