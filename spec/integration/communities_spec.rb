require File.dirname(__FILE__) + '/../spec_helper'

describe "Communities" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!

    @user_non_member = User.gen
    @name_of_create_button = 'Create'

    # @community has all expected data including feeds
    @community = Community.gen
    @user_community_administrator = User.gen
    @user_community_member = User.gen
    @community.initialize_as_created_by(@user_community_administrator)
    @community_member = @community.add_member(@user_community_member)
    @community_member.add_role Role.gen(:community => @community)
    @community.feed.post @feed_body_1 = "Something"
    @community.feed.post @feed_body_2 = "Something Else"
    @community.feed.post @feed_body_3 = "Something More"
    @tc1 = build_taxon_concept
    @tc2 = build_taxon_concept
    @community.focus.add(@tc1)
    @community.focus.add(@tc2)

    # Empty community, no feeds
    @empty_community = Community.gen

  end

  shared_examples_for 'all users' do

    context 'visiting index' do
      before(:all) { visit communities_path }
      subject { body }
      # WARNING: Regarding use of subject, if you are using with_tag you must specify body.should... due to bug.
      # @see https://rspec.lighthouseapp.com/projects/5645/tickets/878-problem-using-with_tag
      it 'should list all communities by name' do
        should have_tag('ul#communities_index li a', /#{@community.name}/)
        should have_tag('ul#communities_index li a', /#{@empty_community.name}/)
      end
      it 'should show a link to create a new community' do
        should have_tag("a[href=?]", /#{new_community_path}.*/)
      end
    end

    context 'visiting show community' do
      before(:all) { visit community_path(@community) }
      subject { body }
      it 'should show the community name and description' do
        should have_tag('h1', /.*?#{@community.name}/)
        should have_tag('p#community_description', /.*?#{@community.description}/)
      end
      it 'should link to community roles' do
        body.should have_tag('ul#community_roles') do
          @community.roles.each do |role|
            with_tag("a[href=#{community_role_path(@community, role)}]", :text => /#{role.title}/m)
          end
        end
      end
      it 'should show count of members with any given role' do
        body.should have_tag('ul#community_roles') do
          @community.roles.each do |role|
            count = role.members.length
            count = 'no' if count == 0
            with_tag("li", :text => /#{role.title}.*#{count}/m)
          end
        end
      end
      it 'should link to all of the community members' do
        body.should have_tag("ul#community_members") do
          @community.members.each do |member|
            user = member.user
            with_tag("a[href=#{user_path(user)}]", :text => user.username)
          end
        end
      end
      it 'should show each member\'s roles' do
        body.should have_tag("ul#community_members") do
          @community.members.each do |member|
            user = member.user
            member.roles.each do |role|
              with_tag("li", :text => /#{user.username}.*#{role.title}/m)
            end
          end
        end
      end
      it 'should show the taxon concepts the community is focused upon' do
        body.should have_tag('#community_focus_container') do
          with_tag("a[href=#{taxon_concept_path(@tc1)}]")
          with_tag("a[href=#{taxon_concept_path(@tc2)}]")
        end
      end
    end
  end

  shared_examples_for 'logged in user' do
    # Make sure you are logged in prior to calling this shared example group
    it_should_behave_like 'all users'
    context 'visiting create community' do
      before(:all) { visit new_community_path }
      it 'should ask for the new community name and description' do
        body.should have_tag("input#community_name")
        body.should have_tag("textarea#community_description")
      end
      it 'should create a community, add the user, and redirect to show on create' do
        fill_in('community_name', :with => 'Some New Name')
        fill_in('community_description', :with => 'This is a long decription.')
        click_button(@name_of_create_button)
        current_path.should == community_path(Community.last)
      end
    end
    context 'visiting show community with feeds' do
      before(:all) { visit community_path(@community) }
      it 'should show feed items' do
        body.should have_tag('ul.feed') do
          with_tag('.feed_item .body', :text => @feed_body_1)
          with_tag('.feed_item .body', :text => @feed_body_2)
          with_tag('.feed_item .body', :text => @feed_body_3)
        end
      end
    end
    context 'visiting show community with empty feed' do
      before(:all) { visit community_path(@empty_community) }
      it 'should show empty feed message' do
        body.should have_tag('#feed_items_container', :text => /no activity/i)
      end
    end
  end

  shared_examples_for 'community member' do
    # Make sure you are logged in prior to calling this shared example group
    it_should_behave_like 'logged in user'

    context 'visiting show community' do
      before(:all) { visit community_path(@community) }
      subject { body }
      it 'should not show join community link' do
        should_not have_tag("a[href=?]", /#{join_community_path(@community.id)}.*/)
      end
      it 'should show leave community link' do
        should have_tag("a[href=?]", /#{leave_community_path(@community.id)}.*/)
      end
    end
  end


  describe 'anonymous user' do
    before(:all) do
      # Make sure we are logged out
      login_as @user_non_member
      visit logout_path
    end
    it_should_behave_like 'all users'
    context 'visiting create community' do
      it 'should require login' do
        get new_community_path
        response.should be_redirect
        response.body.should_not have_tag("input#community_name")
      end
    end
    context 'visiting show community' do
      before(:all) { visit community_path(@community) }
      it 'should show a link to join the community' do
        body.should have_tag("#community_members_container") do
          with_tag("a[href=?]", /#{join_community_path(@community.id)}\?return_to=.*/)
        end
      end
    end
  end

  describe 'non member' do
    before(:all) { login_as @user_non_member }
    it_should_behave_like 'logged in user'
    context 'visiting show community' do
      before(:all) { visit community_path(@community) }
      subject { body }
      it 'should not show edit community links' do
        should_not have_tag("a[href=#{edit_community_path(@community)}]")
      end
      it 'should not show delete community links' do
        should_not have_tag("a[href=#{community_path(@community)}]", :text => /delete/i)
      end
      it 'should allow user to join community' do
        @user_non_member.member_of?(@community).should_not be_true
        should have_tag("a[href=#{join_community_path(@community.id)}]")
        visit(join_community_path(@community.id))
        @user_non_member.reload
        @user_non_member.member_of?(@community).should be_true
        body.should have_tag("ul#community_members") do
          with_tag("li.member a[href=#{user_path(@user_non_member)}]", :text => @user_non_member.username)
        end
        # Clean up - we have tested that a non member can join, we now make them leave
        @user_non_member.leave_community(@community)
        @user_non_member.member_of?(@community).should_not be_true
      end
    end
    context 'visiting edit community' do
      it 'should not be allowed' do
        get edit_community_path(@community)
        response.should be_redirect
      end
    end
  end

  describe 'community member without community administration privileges' do
    before(:all) { login_as @user_community_member }
    it_should_behave_like 'community member'

    context 'visiting show community' do
      before(:all) { visit community_path(@community) }
      subject { body }
      it 'should not show an edit community link' do
        should_not have_tag("a[href=#{edit_community_path(@community)}]")
      end
      it 'should not show a delete community link' do
        should_not have_tag("a[href=#{community_path(@community)}]", :text => /delete/i)
      end
      it 'should not show edit membership links' do
        should_not have_tag("a[href=#{community_member_path(@community, @community_member)}]", :text => /edit/i)
      end
      it 'should not show remove membership links' do
        should_not have_tag("a[href=#{community_member_path(@community, @community_member)}]", :text => /remove/i)
      end
      it 'should not show an add role link' do
        should_not have_tag("a[href=#{new_community_role_path(@community)}]")
      end
      it 'should allow member to leave community and return to show community' do
        @user_community_member.member_of?(@community).should be_true
        visit(leave_community_path(@community.id))
        @user_community_member.reload
        @user_community_member.member_of?(@community).should_not be_true
        body.should have_tag("ul#community_members") do
          without_tag("li.allowed a[href=#{user_path(@user_community_member)}]", :text => @user_community_member.username)
        end
        # Clean up - we have tested that a member can leave a community, now we make them join back
        @user_community_member.join_community(@community)
        @user_community_member.member_of?(@community).should be_true
      end
    end
  end

  describe 'community member with community administration privileges' do
    before(:all) { login_as @user_community_administrator }
    it_should_behave_like 'community member'

    context 'visiting show community' do
      before(:all) { visit community_path(@community) }
      subject { body }
      it 'should show an add role link' do
        should have_tag("a[href=#{new_community_role_path(@community)}]")
      end
      it 'should show an edit community link' do
        should have_tag("a[href=#{edit_community_path(@community)}]")
      end
      it 'should show delete community link' do
        should have_tag("a[href=#{community_path(@community)}]", :text => /delete/i)
      end
      it 'should show edit membership links' do
        should have_tag("a[href=#{community_member_path(@community, @community_member)}]", :text => /edit/i)
      end
      it 'should show remove membership links' do
        should have_tag("a[href=#{community_member_path(@community, @community_member)}]", :text => /remove/i)
      end
    end
    context 'visiting edit community' do
      before(:all) { visit edit_community_path(@community) }
      subject { body }
      it 'should allow editing of name and description' do
        should have_tag("input#community_name")
        should have_tag("textarea#community_description")
      end
    end
  end
end
