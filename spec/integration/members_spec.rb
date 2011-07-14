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
    @privilege1 = TranslatedPrivilege.gen.privilege
    @privilege2 = TranslatedPrivilege.gen.privilege
    @revoked_privilege = TranslatedPrivilege.gen.privilege
    @nonmember = User.gen
    @community.initialize_as_created_by(@admin)
    @member = @community.add_member(@user)
    @member.add_role(@role1)
    @member.add_role(@role2)
    @member.grant_privilege(@privilege1)
    @member.grant_privilege(@privilege2)
    @member.revoke_privilege(@revoked_privilege)
    visit logout_path
    visit community_members_path(@community)
    @community_nonmembers_page = page.body
    login_as @member
    visit community_member_path(@community, @member)
    @community_member_page = page.body
    login_as @admin
    visit community_member_path(@community, @member)
    @community_admin_page = page.body
  end

  it 'nonmembers should list members of a community' do
    @community_nonmembers_page.should have_tag('#community', :text => /#{@admin.short_name}/)
    @community_nonmembers_page.should have_tag('#community', :text => /#{@user.short_name}/)
    @community_nonmembers_page.should_not have_tag('#community', :text => /#{@nonmember.short_name}/)
  end

  it 'admins should (still) have a link to the user\'s page' do
    @community_admin_page.should have_tag("a[href=#{user_path(@user)}]")
  end

  it 'admins should have an grant-role drop-down' do
    @community_admin_page.should have_tag('.roles .add') do
      with_tag('select#member_new_role_id')
    end
  end

  it 'admins should list a member\'s roles with remove links' do
    @community_admin_page.should have_tag('ul#roles') do
      [@role1, @role2].each do |role|
        with_tag('li', :text => /#{role.title}/) do
          with_tag("a[href*=remove_role]", :text => /remove/i)
        end
      end
    end
  end

  it 'admins should list a member\'s privilegs with revoke links' do
    @community_admin_page.should have_tag('ul#privileges') do
      with_tag('li', :text => /#{@privilege1.name}/) do
        with_tag("a[href*=revoke_privilege_from]", :text => /remove/i)
      end
      with_tag('li', :text => /#{@privilege2.name}/) do
        with_tag("a[href*=revoke_privilege_from]", :text => /remove/i)
      end
    end
  end

  it 'admins should have a grant privilege drop-down' do
    @community_admin_page.should have_tag('.privileges .add') do
      with_tag('select#member_new_privilege_id')
    end
  end

  it 'admins should have a revoke privilege drop-down' do
    @community_admin_page.should have_tag('.privileges .add') do
      with_tag('select#member_removed_privilege_id')
    end
  end

  it 'admins should list a member\'s revoked privilegs with restore links' do
    @community_admin_page.should have_tag('ul#privileges') do
      with_tag('li', :text => /#{@revoked_privilege.name}.*revoked/im) do
        with_tag("a[href*=grant_privilege]", :text => /remove/i)
      end
    end
  end

  it 'admins should be able to manage the community' do
    # Add Privilege:
    privs = Privilege.find(:all, :conditions => { :special => false }).map(&:name)
    visit community_member_path(@community, @member)
    select privs.first, :from => 'member_new_privilege_id'
    click 'Grant Privilege'
    page.body.should have_tag('ul#privileges') do
      with_tag('li', :text => /#{privs.first}/)
    end
    # 'should be able to revoke privileges' do
    select privs[1], :from => 'member_removed_privilege_id'
    click 'Revoke Privilege'
    page.body.should have_tag('ul#privileges') do
      with_tag('li', :text => /#{privs[1]}/)
    end
    # 'should be able to add a role' do
    select @role3.title, :from => 'member_new_role_id'
    click 'Add Role'
    page.body.should have_tag('ul#roles') do
      with_tag('li', :text => /#{@role3.title}/)
    end
  end

  # TODO
  it 'should be able to remove revoked privileges'
  it 'should be able to remove a role'

  it 'members should have a link to the user\'s page' do
    @community_member_page.should have_tag("a[href=#{user_path(@user)}]")
  end

  it 'members should list a member\'s roles' do
    @community_member_page.should have_tag('ul#roles') do
      with_tag('li', :text => @role1.title)
      with_tag('li', :text => @role2.title)
      without_tag('li', :text => @role3.title)
      without_tag("a[href*=remove_role]", :text => /remove/i)
    end
  end

  it 'members should list a member\'s privilegs (including revoked)' do
    @community_member_page.should have_tag('ul#privileges') do
      with_tag('li', :text => @privilege1.name)
      with_tag('li', :text => @privilege2.name)
      with_tag('li', :text => /#{@revoked_privilege.name}.*revoked/im)
    end
  end

  it 'members should NOT have a grant privilege drop-down' do
    @community_member_page.should have_tag('.privileges .add') do
      without_tag('select#member_new_privilege_id')
    end
  end

  it 'members should NOT have a revoke privilege drop-down' do
    @community_member_page.should have_tag('.privileges .add') do
      without_tag('select#member_removed_privilege_id')
    end
  end

  it 'members should NOT have a grant role drop-down' do
    @community_member_page.should have_tag('.privileges .add') do
      without_tag('select#member_new_role_id')
    end
  end

end
