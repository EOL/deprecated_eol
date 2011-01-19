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

  describe 'show (to an admin)' do

    before(:each) do
      login_as @admin
      visit community_member_path(@community, @member)
    end

    it 'should (still) have a link to the user\'s page' do
      page.body.should have_tag("a[href=#{user_path(@user)}]")
    end

    it 'should have an grant-role drop-down' do
      page.body.should have_tag('.roles .add') do
        with_tag('select#member_new_role_id')
      end
    end

    it 'should list a member\'s roles with remove links' do
      page.body.should have_tag('ul#roles') do
        [@role1, @role2].each do |role|
          with_tag('li', :text => /#{role.title}/) do
            with_tag("a[href*=remove_role]", :text => /remove/i)
          end
        end
      end
    end

    it 'should list a member\'s privilegs with revoke links' do
      page.body.should have_tag('ul#privileges') do
        with_tag('li', :text => /#{@privilege1.name}/) do
          with_tag("a[href*=revoke_privilege_from]", :text => /remove/i)
        end
        with_tag('li', :text => /#{@privilege2.name}/) do
          with_tag("a[href*=revoke_privilege_from]", :text => /remove/i)
        end
      end
    end

    it 'should have a grant privilege drop-down' do
      page.body.should have_tag('.privileges .add') do
        with_tag('select#member_new_privilege_id')
      end
    end

    it 'should have a revoke privilege drop-down' do
      page.body.should have_tag('.privileges .add') do
        with_tag('select#member_removed_privilege_id')
      end
    end

    it 'should list a member\'s revoked privilegs with restore links' do
      page.body.should have_tag('ul#privileges') do
        with_tag('li', :text => /#{@revoked_privilege.name}.*revoked/im) do
          with_tag("a[href*=grant_privilege]", :text => /remove/i)
        end
      end
    end

    it 'should be able to grant privileges' do
      priv_name = KnownPrivileges.community.keys[0]
      select priv_name, :from => 'member_new_privilege_id'
      click 'Grant Privilege'
      page.body.should have_tag('ul#privileges') do
        with_tag('li', :text => /#{priv_name}/)
      end
    end

    it 'should be able to revoke privileges' do
      priv_name = KnownPrivileges.community.keys[1]
      select priv_name, :from => 'member_removed_privilege_id'
      click 'Revoke Privilege'
      page.body.should have_tag('ul#privileges') do
        with_tag('li', :text => /#{priv_name}/)
      end
    end

    it 'should be able to add a role' do
      select @role3.title, :from => 'member_new_role_id'
      click 'Add Role'
      page.body.should have_tag('ul#roles') do
        with_tag('li', :text => /#{@role3.title}/)
      end
    end

    # TODO - these don't work because I can't get the right "remove" link to be clicked. The "within" function does not work
    # as advertised and throws a "scope not found" error.
    it 'should be able to remove revoked privileges'
    it 'should be able to remove a role'

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
        without_tag("a[href*=remove_role]", :text => /remove/i)
      end
    end

    it 'should list a member\'s privilegs (including revoked)' do
      page.body.should have_tag('ul#privileges') do
        with_tag('li', :text => @privilege1.name)
        with_tag('li', :text => @privilege2.name)
        with_tag('li', :text => /#{@revoked_privilege.name}.*revoked/im)
      end
    end

    it 'should NOT have a grant privilege drop-down' do
      page.body.should have_tag('.privileges .add') do
        without_tag('select#member_new_privilege_id')
      end
    end

    it 'should NOT have a revoke privilege drop-down' do
      page.body.should have_tag('.privileges .add') do
        without_tag('select#member_removed_privilege_id')
      end
    end

    it 'should NOT have a grant role drop-down' do
      page.body.should have_tag('.privileges .add') do
        without_tag('select#member_new_role_id')
      end
    end

  end

end
