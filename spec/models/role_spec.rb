require 'spec_helper'

describe Role do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
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

  # Technically, this tests what's in foundation.  But still.
  it 'should find the special community role with $CURATOR_ROLE_NAME' do
    Role.curator.title.should == $CURATOR_ROLE_NAME
  end

  # Technically, this tests what's in foundation.  But still.
  it 'should find the special community role with $ADMIN_ROLE_NAME' do
    Role.administrator.title.should == $ADMIN_ROLE_NAME
  end

  it 'should add a privilege' do
    @role.privileges.include?(@new_priv).should_not be_true
    @role.add_privilege(@new_priv)
    @role.privileges.include?(@new_priv).should be_true
  end

  it 'should generate the admin role on a given community' do
    @community.roles.should == []
    Role.add_defaults_to_community(@community)
    @community.roles.map {|r| r.title}.sort.should == ['Admin']
  end

  it 'should #count the number of members with the role' do
    r = Role.gen(:community => @community)
    6.times do
      m = Member.gen(:community => @community)
      m.add_role(r)
    end
    r.count.should == 6
  end

end
