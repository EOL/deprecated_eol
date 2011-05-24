require 'spec_helper'

describe Privilege do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
  end

  it '#create_defaults should create some defaults' do
    priv = Privilege.last
    Privilege.should_receive(:create).at_least(10).times.and_return(priv) # Doesn't matter what it returns as long as it has an ID...
    TranslatedPrivilege.should_receive(:create).at_least(10).times.and_return(nil)
    Privilege.create_defaults
  end

  it 'should return ALL of the privileges associated with a special community (sorted by name)' do
    privs = Privilege.all_for_community(Community.special)
    privs.should_not be_empty
    Privilege.all.sort_by(&:name).should == privs
  end

  it 'should return all of the non-special privileges associated with a non-special community (sorted by name)' do
    c = Community.gen
    privs = Privilege.all_for_community(c)
    privs.should_not be_empty
    privs.each do |p|
      p.special.should_not be_true
    end
    privs.sort_by(&:name).should == privs
  end

  it 'should make methods based on each new priv name' do
    p = TranslatedPrivilege.gen(:name => 'humblenevitt').privilege
    p.save!
    Privilege.humblenevitt.id.should == p.id
  end

  it 'should know about member-editing privs' do # I don't much care if they change, but they must exist:
    Privilege.member_editing_privileges.length.should >= 1
  end

end
