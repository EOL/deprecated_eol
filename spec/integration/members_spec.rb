require File.dirname(__FILE__) + '/../spec_helper'

describe "Members controller (within a community)" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @community = Community.gen
    @admin = User.gen
    @member = User.gen
    @nonmember = User.gen
    @community.initialize_as_created_by(@admin)
    @community.add_member(@member)
  end

  it 'should list members of a community' do
    visit community_members_path(@community)
    page.should have_content(@admin.username)
    page.should have_content(@member.username)
    page.should_not have_content(@nonmember.username)
  end

end
