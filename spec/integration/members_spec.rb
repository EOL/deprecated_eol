require File.dirname(__FILE__) + '/../spec_helper'

describe "Members controller (within a community)" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @community = Community.gen
    @admin = User.gen
    @user = User.gen
    @role1 = Role.gen(:community => @community)
    @role2 = Role.gen(:community => @community)
    @role3 = Role.gen(:community => @community)
    @privilege1 = Privilege.gen
    @privilege2 = Privilege.gen
    @privilege3 = Privilege.gen
    @revoked_privilege = Privilege.gen
    @nonmember = User.gen
    @community.initialize_as_created_by(@admin)
    @member = @community.add_member(@user)
    @member.add_role(@role1)
    @member.add_role(@role2)
    @member.grant_privilege(@privilege1)
    @member.grant_privilege(@privilege2)
    @member.revoke_privilege(@revoked_privilege)
  end

  it 'should list members of a community' do
    visit community_members_path(@community)
    page.should have_content(@admin.username)
    page.should have_content(@user.username)
    page.should_not have_content(@nonmember.username)
  end

  describe 'show (to a non-admin)' do

    before(:each) do
      visit community_member_path(@community, @member)
    end

    it 'should have a link to the user\'s page' do
      page.body.should have_tag("a[href=#{user_path(@user)}]")
    end

    it 'should list a member\'s roles' do
      page.body.should have_tag('ul#roles') do
        with_tag('li', :text => @role1.title)
        with_tag('li', :text => @role2.title)
        without_tag('li', :text => @role3.title)
        without_tag("a[href=#{remove_role_path(:member_id => @member.id, :role_id => @role1.id)}]")
      end
    end

    it 'should list a member\'s privilegs (including revoked)' do
      page.body.should have_tag('ul#privileges') do
        with_tag('li', :text => @privilege1.name)
        with_tag('li', :text => @privilege2.name)
        with_tag('li', :text => /#{@revoked_privilege.name}.*revoked/im)
      end
    end

  end

  describe 'show (to an admin)' do

    before(:each) do
      login_as @admin
      visit community_member_path(@community, @member)
    end

    it 'should (still) have a link to the user\'s page' do
      page.body.should have_tag("a[href=#{user_path(@user)}]")
    end

    it 'should list a member\'s roles with remove links' do
      page.body.should have_tag('ul#roles') do
        [@role1, @role2].each do |role|
          with_tag('li', :text => /#{role.title}/) do
            with_tag("a[href=#{remove_role_path(:member_id => @member.id, :role_id => role.id)}]")
          end
        end
      end
    end

    it 'should list a member\'s privilegs (including revoked)' do
      page.body.should have_tag('ul#privileges') do
        with_tag('li', :text => /#{@privilege1.name}/)
        with_tag('li', :text => /#{@privilege2.name}/)
        with_tag('li', :text => /#{@revoked_privilege.name}.*revoked/im)
      end
    end

  end

end
