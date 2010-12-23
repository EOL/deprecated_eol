require 'spec_helper'

describe Role do

  before(:each) do
    @special = Community.gen
    Community.stub!(:special).and_return(@special)
    @curator = Role.gen(:title => $CURATOR_ROLE_NAME, :community_id => @special.id)
    @admin = Role.gen(:title => $ADMIN_ROLE_NAME, :community_id => @special.id)
    @new_priv = Privilege.gen
    @role = Role.gen
    @community = Community.gen
  end

  before(:each) do
    @role.privileges = []
  end

  it 'should NOT validate if missing a title' do
    r = Role.new(:title => '')
    r.valid?.should_not be_true
  end
  
  it 'should find the special community role with $CURATOR_ROLE_NAME' do
    Role.curator.should == @curator
  end

  it 'should find the special community role with $ADMIN_ROLE_NAME' do
    Role.administrator.should == @admin
  end

  it 'should add a privilege' do
    @role.privileges.include?(@new_priv).should_not be_true
    @role.add_privilege(@new_priv)
    @role.privileges.include?(@new_priv).should be_true
  end

  it 'should generate a set of roles on a given community' do
    @community.roles.should == []
    Role.add_defaults_to_community(@community)
    @community.roles.map {|r| r.title}.sort.should == ['Content Manager', 'Member Services Manager','Owner']
  end

end
