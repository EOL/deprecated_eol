require File.dirname(__FILE__) + '/../spec_helper'

describe "Communities controller" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @community = Community.gen
    @user1 = User.gen # It's important that user1 NOT be a member of community2
    @user2 = User.gen
    @role = Role.gen(:community => @community)
    @community.initialize_as_created_by(@user1)
    @member2 = @community.add_member(@user2)
    @member2.add_role @role
    @community2 = Community.gen # It's important that user1 NOT be a member of community2
    @name_of_create_button = 'Create'
    @tc1 = build_taxon_concept
    @tc2 = build_taxon_concept
    @community.focus.add(@tc1)
    @community.focus.add(@tc2)
  end

  describe '#index' do

    it 'should list all communities by name' do
      visit communities_path
      page.should have_content(@community.name)
      page.should have_content(@community2.name)
    end

    it 'should link to creating a new community' do
      visit communities_path
      # TODO - Why is capybara'a "have_selector" not working?
      page.body.should have_tag("a[href=#{new_community_path}]")
    end

  end

  describe "#new" do

    before(:each) do
      login_as @user1
    end

    it 'should not allow non-logged-in users' do
      visit logout_path
      get new_community_path
      response.should be_redirect
      response.body.should_not have_tag("input#community_name")
    end

    it 'should ask for the new community name and description' do
      visit new_community_path
      page.body.should have_tag("input#community_name")
      page.body.should have_tag("textarea#community_description")
    end

    it 'should create a community, add the user, and redirect to show on create' do
      visit new_community_path
      fill_in('community_name', :with => 'Some New Name')
      fill_in('community_description', :with => 'This is a long decription.')
      click_button(@name_of_create_button)
      current_path.should == community_path(Community.last)
    end

  end

  describe '#show' do

    it 'should show the community name and description' do
      visit community_path(@community)
      page.should have_content(@community.name)
      page.should have_content(@community.description)
    end

    it 'should link to all of the community roles (including member count)' do
      visit community_path(@community)
      page.body.should have_tag('ul#community_roles') do
        @community.roles.each do |role|
          count = role.members.length # inefficient, but accurate
          count = 'no' if count == 0
          with_tag("li", :text => /#{role.title}.*#{count}/m) do
            with_tag("a[href=#{community_role_path(@community, role)}]", :text => /#{role.title}/m)
          end
        end
      end
    end

    it 'should link to all of the community members' do
      visit community_path(@community)
      page.body.should have_tag("ul#community_members") do
        @community.members.each do |member|
          user = member.user
          with_tag("a[href=#{user_path(user)}]", :text => user.username)
        end
      end
    end
    
    it 'should list each member\'s roles' do
      visit community_path(@community)
      page.body.should have_tag("ul#community_members") do
        @community.members.each do |member|
          user = member.user
          member.roles.each do |role|
            with_tag("li", :text => /#{user.username}.*#{role.title}/m)
          end
        end
      end
    end

    it 'should show the "focus"' do
      page.body.should have_tag('.focus') do
        with_tag("a[href=#{taxon_concept_path(@tc1)}]")
        with_tag("a[href=#{taxon_concept_path(@tc2)}]")
      end
    end

    describe '(with owner logged in)' do

      before(:all) do
        login_as @user1
        visit community_path(@community)
      end

      it 'should show the add role link' do
        page.body.should have_tag("a[href=#{new_community_role_path(@community)}]")
      end

      it 'should show edit and delete links' do
        page.body.should have_tag("a[href=#{edit_community_path(@community)}]")
        page.body.should have_tag("a[href=#{community_path(@community)}]", :text => /delete/i)
      end

      it 'should show edit membership links' do
        page.body.should have_tag("a[href=#{community_member_path(@community, @member2)}]", :text => /edit/i)
      end

      it 'should show remove membership links' do
        # NOTE = this is doesn't test that the link is actually a DELETE... but that's fine, it checks the text:
        page.body.should have_tag("a[href=#{community_member_path(@community, @member2)}]", :text => /remove/i)
      end

    end

    it 'should show log in message when not logged in' do
      visit community_path(@community)
      page.body.should have_tag("#full-page-content") do # Make sure we're not looking at the header.
        with_tag("a[href=#{login_path}]")
      end
    end

    describe '(with member logged in)' do

      before(:all) do
        @community_with_membership_but_no_access = Community.gen
        @user1.join_community(@community_with_membership_but_no_access)
        login_as @user2
        visit community_path(@community)
      end

      it 'should show leave link' do
        page.body.should have_tag("a[href=#{leave_community_path(@community.id)}]")
      end

      it 'should NOT show the add role link' do
        page.body.should_not have_tag("a[href=#{new_community_role_path(@community)}]")
      end

      it 'should NOT show edit and delete links' do
        page.body.should_not have_tag("a[href=#{edit_community_path(@community)}]")
        page.body.should_not have_tag("a[href=#{community_path(@community)}]", :text => /delete/i)
        page.body.should_not have_tag("a[href=#{join_community_path(@community2.id)}]")
      end

      it 'should show NOT edit membership links' do
        page.body.should_not have_tag("a[href=#{community_member_path(@community, @member2)}]", :text => /edit/i)
      end

      it 'should show NOT remove membership links' do
        # NOTE = this is doesn't test that the link is actually a DELETE... but that's fine, it checks the text:
        page.body.should_not have_tag("a[href=#{community_member_path(@community, @member2)}]", :text => /remove/i)
      end

      it 'should NOT show logged-in message' do
        page.body.should_not have_tag("a[href=#{login_path}]", :text => /must be logged in/)
      end

    end

    describe '(with non-member logged in)' do

      before(:all) do
        login_as @user1
        visit community_path(@community2)
      end

      it 'should show join link and NOT edit or delete links when logged-in user is NOT a member' do
        page.body.should have_tag("a[href=#{join_community_path(@community2.id)}]")
        page.body.should_not have_tag("a[href=#{edit_community_path(@community)}]")
        page.body.should_not have_tag("a[href=#{community_path(@community)}]", :text => /delete/i)
      end

    end

  end

  describe '#edit' do

    it 'should not allow non-members' do
      # NOTE - Capybara doesn't want you testing redirects.  It says "use a unit test".  Really.
      get edit_community_path(@community)
      response.should be_redirect
    end

    it 'should allow editing of name and description (as community owner)' do
      login_as @user1
      visit edit_community_path(@community)
      page.body.should have_tag("input#community_name")
      page.body.should have_tag("textarea#community_description")
    end

  end

  it 'should allow non-members to join communities, then redirect to show' do
    login_as @user1
    @user1.member_of?(@community2).should_not be_true
    visit(join_community_path(@community2.id))
    @user1.reload
    @user1.member_of?(@community2).should be_true
    page.body.should have_tag("ul#community_members") do
      with_tag("li.allowed a[href=#{user_path(@user1)}]", :text => @user1.username)
    end
    # Clean-up:
    @user1.leave_community(@community2)
    visit(logout_path)
  end

  it 'should allow members to leave communities, then redirect to show' do
    login_as @user1
    @user1.member_of?(@community).should be_true
    visit(leave_community_path(@community.id))
    @user1.reload
    @user1.member_of?(@community).should_not be_true
    page.body.should have_tag("ul#community_members") do
      without_tag("li.allowed a[href=#{user_path(@user1)}]", :text => @user1.username)
    end
    # Clean-up:
    @user1.join_community(@community)
    visit(logout_path)
  end

end
