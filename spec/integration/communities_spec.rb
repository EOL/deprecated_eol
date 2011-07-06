require File.dirname(__FILE__) + '/../spec_helper'

describe "Communities" do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('communities_scenario')
      truncate_all_tables
      load_scenario_with_caching(:communities)
    end
    Capybara.reset_sessions!
    @test_data = EOL::TestInfo.load('communities')
  end

  shared_examples_for 'communities all users' do

    context 'visiting index' do
      before(:all) { visit communities_path }
      subject { body }
      # WARNING: Regarding use of subject, if you are using with_tag you must specify body.should... due to bug.
      # @see https://rspec.lighthouseapp.com/projects/5645/tickets/878-problem-using-with_tag
      it 'should list all communities by name' do
        should have_tag('ul#communities_index li a', /#{@test_data[:community].name}/)
        should have_tag('ul#communities_index li a', /#{@test_data[:empty_community].name}/)
      end
      it 'should show a link to create a new community' do
        should have_tag("a[href=?]", /#{new_community_path}.*/)
      end
    end

    context 'visiting show community' do
      before(:all) { visit community_path(@test_data[:community]) }
      subject { body }
      it 'should show the community name and description' do
        should have_tag('h1', /.*?#{@test_data[:community].name}/)
        should have_tag('#page_heading', /#{@test_data[:community].description}/)
      end
      it 'should link to community roles'
# maybe but not on default show tab
#        body.should have_tag('ul#community_roles') do
#          @test_data[:community].roles.each do |role|
#            with_tag("a[href=#{community_role_path(@test_data[:community], role)}]", :text => /#{role.title}/m)
#          end
#        end

      it 'should show count of members with any given role'
# maybe but not on default show tab
#        body.should have_tag('ul#community_roles') do
#          @test_data[:community].roles.each do |role|
#            count = role.members.length
#            count = 'no' if count == 0
#            with_tag("li", :text => /#{role.title}.*#{count}/m)
#          end
#        end

      it 'should link to all of the community members'
# maybe but not on default show tab
#        body.should have_tag("ul#community_members") do
#          @test_data[:community].members.each do |member|
#            user = member.user
#            with_tag("a[href=#{user_path(user)}]", :text => user.username)
#          end
#        end

      it 'should show each member\'s roles'
# maybe but not on default show tab
#        body.should have_tag("ul#community_members") do
#          @test_data[:community].members.each do |member|
#            user = member.user
#            member.roles.each do |role|
#              with_tag("li", :text => /#{user.username}.*#{role.title}/m)
#            end
#          end
#        end

      it 'should show the collection the community is focused upon' do
        body.should have_tag('#sidebar') do
          with_tag("a[href=#{collection_path(@test_data[:community].focus.id)}]", :text => /#{@test_data[:community].focus.name}/)
        end
      end
    end
  end

  shared_examples_for 'communities logged in user' do
    # Make sure you are logged in prior to calling this shared example group
    it_should_behave_like 'communities all users'
    context 'visiting create community' do
      before(:all) { visit new_community_path }
      it 'should ask for the new community name and description' do
        body.should have_tag("input#community_name")
        body.should have_tag("textarea#community_description")
      end
      it 'should create a community, add the user, and redirect to community default view' do
        fill_in('community_name', :with => 'Some New Name')
        fill_in('community_description', :with => 'This is a long decription.')
        click_button(@test_data[:name_of_create_button])
        current_path.should match /#{community_path(Community.last)}/
      end
    end
    # TODO - ActivityLog
  end

  shared_examples_for 'community member' do
    # Make sure you are logged in prior to calling this shared example group
    it_should_behave_like 'communities logged in user'

    context 'visiting show community' do
      before(:all) { visit community_path(@test_data[:community]) }
      subject { body }
      it 'should not show join community link'
        # probably but not defined in design yet
        # should_not have_tag("a[href=?]", /#{join_community_path(@test_data[:community].id)}.*/)
      it 'should show leave community link'
        # probably but not sure where yet...?
        # should have_tag("a[href=?]", /#{leave_community_path(@test_data[:community].id)}.*/)

    end
  end


  describe 'anonymous user' do
    before(:all) do
      # Make sure we are logged out
      login_as @test_data[:user_non_member]
      visit logout_path
    end
    it_should_behave_like 'communities all users'
    context 'visiting create community' do
      it 'should require login' do
        get new_community_path
        response.should be_redirect
        response.body.should_not have_tag("input#community_name")
      end
    end
    context 'visiting show community' do
      before(:all) { visit community_path(@test_data[:community]) }
      it 'should show a link to join the community' do
        body.should have_tag("#page_heading") do
          with_tag("a[href=?]", /#{join_community_path(@test_data[:community].id)}\?return_to=.*/)
        end
      end
    end
  end

  describe 'non member' do
    before(:all) { login_as @test_data[:user_non_member] }
    it_should_behave_like 'communities logged in user'
    context 'visiting show community' do
      before(:all) { visit community_path(@test_data[:community]) }
      subject { body }
      it 'should not show edit community links' do
        should_not have_tag("a[href=#{edit_community_path(@test_data[:community])}]")
      end
      it 'should not show delete community links' do
        should_not have_tag("a[href=#{community_path(@test_data[:community])}]", :text => /delete/i)
      end
      it 'should allow user to join community' do
        @test_data[:user_non_member].member_of?(@test_data[:community]).should_not be_true
        should have_tag("a[href=?]", /#{join_community_path(@test_data[:community].id)}.*/)
        visit(join_community_path(@test_data[:community].id))
        @test_data[:user_non_member].reload
        @test_data[:user_non_member].member_of?(@test_data[:community]).should be_true
        # Clean up - we have tested that a non member can join, we now make them leave
        @test_data[:user_non_member].leave_community(@test_data[:community])
        @test_data[:user_non_member].member_of?(@test_data[:community]).should_not be_true
      end
    end
    context 'visiting edit community' do
      it 'should not be allowed' do
        get edit_community_path(@test_data[:community])
        response.should be_redirect
      end
    end
  end

  describe 'community member without community administration privileges' do
    before(:all) { login_as @test_data[:user_community_member] }
    it_should_behave_like 'community member'

    context 'visiting show community' do
      before(:all) { visit community_path(@test_data[:community]) }
      subject { body }
      it 'should not show an edit community link' do
        should_not have_tag("a[href=#{edit_community_path(@test_data[:community])}]")
      end
      it 'should not show a delete community link' do
        should_not have_tag("a[href=#{community_path(@test_data[:community])}]", :text => /delete/i)
      end
      it 'should not show edit membership links' do
        should_not have_tag("a[href=#{community_member_path(@test_data[:community], @test_data[:community_member])}]", :text => /edit/i)
      end
      it 'should not show remove membership links' do
        should_not have_tag("a[href=#{community_member_path(@test_data[:community], @test_data[:community_member])}]", :text => /remove/i)
      end
      it 'should not show an add role link' do
        should_not have_tag("a[href=#{new_community_role_path(@test_data[:community])}]")
      end
      it 'should allow member to leave community and return to show community' do
        @test_data[:user_community_member].member_of?(@test_data[:community]).should be_true
        visit(leave_community_path(@test_data[:community].id))
        @test_data[:user_community_member].reload
        @test_data[:user_community_member].member_of?(@test_data[:community]).should_not be_true
        # Clean up - we have tested that a member can leave a community, now we make them join back
        @test_data[:user_community_member].join_community(@test_data[:community])
        @test_data[:user_community_member].member_of?(@test_data[:community]).should be_true
      end
    end
  end

  describe 'community member with community administration privileges' do
    before(:all) { login_as @test_data[:user_community_administrator] }
    it_should_behave_like 'community member'

    context 'visiting show community' do
      before(:all) { visit community_path(@test_data[:community]) }
      subject { body }
      # Setting to pending until we know what actions will be available on default show tab
      it 'should show an add role link'
#        should have_tag("a[href=#{new_community_role_path(@test_data[:community])}]")
#      end
      it 'should show an edit community link'
#        should have_tag("a[href=#{edit_community_path(@test_data[:community])}]")
#      end
      it 'should show delete community link'
#        should have_tag("a[href=#{community_path(@test_data[:community])}]", :text => /delete/i)
#      end
      it 'should show edit membership links'
#        should have_tag("a[href=#{community_member_path(@test_data[:community], @test_data[:community_member])}]", :text => /edit/i)
#      end
      it 'should show remove membership links'
#        should have_tag("a[href=#{community_member_path(@test_data[:community], @test_data[:community_member])}]", :text => /remove/i)
#      end
    end
    context 'visiting edit community' do
      before(:all) { visit edit_community_path(@test_data[:community]) }
      subject { body }
      it 'should allow editing of name and description' do
        should have_tag("input#community_name")
        should have_tag("textarea#community_description")
      end
    end
  end
end
