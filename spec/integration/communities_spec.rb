require File.dirname(__FILE__) + '/../spec_helper'

describe "Communities" do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('communities_scenario')
      truncate_all_tables
      load_scenario_with_caching(:communities)
      @test_data = EOL::TestInfo.load('communities')
      @collection = Collection.gen
      @collection.add(User.gen)
    end
  end

  shared_examples_for 'communities all users' do

    context 'visiting show community' do
      before(:each) { visit community_path(@test_data[:community]) }
      subject { body }

      it 'should have rel canonical link tag' do
        should have_tag("link[rel=canonical][href$='#{community_newsfeed_path(@test_data[:community])}']")
      end
      it 'should have rel prev and next link tags when appropriate'

      it 'should show the community name and description' do
        should have_tag('h1', :text => @test_data[:community].name)
        should have_tag('#page_heading', :text => @test_data[:community].description)
      end

      it 'should show the collections the community is focused upon' do
        body.should have_tag('#sidebar') do
          @test_data[:community].collections.each do |focus|
            with_tag("a[href='#{collection_path(focus.id)}']", :text => /#{focus.name}/)
          end
        end
      end
    end

    context 'visiting community members' do
      before(:each) { visit community_members_path(@test_data[:community]) }
      subject { body }

      it 'should have rel canonical link tag' do
        should have_tag("link[rel=canonical][href$='#{community_members_path(@test_data[:community])}']")
      end
      it 'should link to all of the community members'
    end
  end

  shared_examples_for 'communities logged in user' do
    # Make sure you are logged in prior to calling this shared example group
    it_should_behave_like 'communities all users'
    context 'visiting create community' do
      before(:each) { visit new_community_path(:collection_id => @collection.id) }
      it 'should ask for the new community name and description' do
        body.should have_tag("input#community_name")
        body.should have_tag("textarea#community_description")
      end
      it 'should create a community, add the user, and redirect to community default view' do
        new_name = FactoryGirl.generate(:string)
        new_col_name = FactoryGirl.generate(:string)
        fill_in('community_name', :with => new_name)
        fill_in('community_description', :with => 'This is a long description.')
        click_button('Create community')
        new_comm = Community.last
        new_comm.name.should == new_name
        new_comm.description.should == 'This is a long description.'
        current_path.should match /#{community_path(new_comm)}/
      end
    end
  end

  shared_examples_for 'community member' do
    # Make sure you are logged in prior to calling this shared example group
    it_should_behave_like 'communities logged in user'

    context 'visiting show community' do
      before(:each) { visit community_path(@test_data[:community]) }
      subject { body }
      it 'should not show join community link'
      it 'should show leave community link'
    end
  end


  describe 'anonymous user' do
    before(:each) do
      visit logout_path
    end
    it_should_behave_like 'communities all users'
    context 'visiting create community' do
      it 'should require login' do
        lambda { get new_community_path(:collection_id => @collection.id) }.should raise_error(EOL::Exceptions::MustBeLoggedIn)
      end
    end
    context 'visiting show community' do
      before(:each) { visit community_path(@test_data[:community]) }
      it 'should show a link to join the community' do
        body.should have_tag("#page_heading") do
          with_tag("a[href='#{join_community_path(@test_data[:community].id)}']")
        end
      end
    end
  end

  describe 'non member' do
    before(:each) { login_as @test_data[:user_non_member] }
    it_should_behave_like 'communities logged in user'
    context 'visiting show community' do
      before(:each) { visit community_path(@test_data[:community]) }
      subject { body }
      it 'should not show edit community links' do
        should_not have_tag("a[href='#{edit_community_path(@test_data[:community])}']")
      end
      it 'should not show delete community links' do
        should_not have_tag("a[href='#{community_path(@test_data[:community])}']", :text => I18n.t(:delete_community))
      end
      it 'should allow user to join community' do
        @test_data[:user_non_member].is_member_of?(@test_data[:community]).should_not be_true
        #  href="/communities/2/join?return_to=%2Fcommunities%2F2"
        should have_tag("a[href='#{join_community_path(@test_data[:community].id)}']")
        visit(join_community_path(@test_data[:community].id))
        @test_data[:user_non_member].reload
        @test_data[:user_non_member].is_member_of?(@test_data[:community]).should be_true
        # Clean up - we have tested that a non member can join, we now make them leave
        @test_data[:user_non_member].leave_community(@test_data[:community])
        @test_data[:user_non_member].is_member_of?(@test_data[:community]).should_not be_true
      end
      it "should not have a share collection button" do
        body.should_not have_tag("a[href='#{choose_editor_target_collections_path(:community_id => @test_data[:community].id)}']",
          :text => 'Share a collection')
      end
    end
    context 'visiting edit community' do
      it 'should not be allowed' do
        lambda { get edit_community_path(@test_data[:community]) }.should
          raise_error(EOL::Exceptions::SecurityViolation)
      end
    end
  end

  describe 'community member without community administration privileges' do
    before(:each) { login_as @test_data[:user_community_member] }
    it_should_behave_like 'community member'

    context 'visiting show community' do
      before(:each) { visit community_path(@test_data[:community]) }
      subject { body }
      it 'should not show an edit community link' do
        should_not have_tag("a[href='#{edit_community_path(@test_data[:community])}']")
      end
      it 'should not show a delete community link' do
        should_not have_tag("a[href='#{community_path(@test_data[:community])}']", :text => I18n.t(:delete_community))
      end
      it 'should not show edit membership links' do
        should_not have_tag("a[href='#{community_member_path(@test_data[:community], @test_data[:community_member])}']", :text => /edit/i)
      end
      it 'should not show remove membership links' do
        should_not have_tag("a[href='#{community_member_path(@test_data[:community], @test_data[:community_member])}']", :text => /remove/i)
      end
      it 'should allow member to leave community and return to show community' do
        @test_data[:user_community_member].is_member_of?(@test_data[:community]).should be_true
        visit(leave_community_path(@test_data[:community].id))
        @test_data[:user_community_member].reload
        @test_data[:user_community_member].is_member_of?(@test_data[:community]).should_not be_true
        # Clean up - we have tested that a member can leave a community, now we make them join back
        @test_data[:user_community_member].join_community(@test_data[:community])
        @test_data[:user_community_member].is_member_of?(@test_data[:community]).should be_true
      end
      it "should not have a share collection button" do
        body.should_not have_tag("a[href='#{choose_editor_target_collections_path(:community_id => @test_data[:community].id)}']",
          :text => 'Share a collection')
      end
    end
  end

  describe 'community member with community administration privileges' do
    before(:each) { login_as @test_data[:user_community_administrator] }
    it_should_behave_like 'community member'

    context 'visiting show community' do
      before(:each) { visit community_path(@test_data[:community]) }
      subject { body }
      # TODO - we could test a few things here.
      it "should have a share collection button" do
        body.should have_tag("a[href='#{choose_editor_target_collections_path(:community_id => @test_data[:community].id)}']",
          :text => 'Share a collection')
      end
      it "should do something" do
        click_link 'Share a collection'
        body.should include("Allow #{@test_data[:community].name} to manage the following collections")
        body.should have_tag("input[type=submit][value='Share a collection']")
      end
    end
    context 'visiting edit community' do
      before(:each) { visit edit_community_path(@test_data[:community]) }
      subject { body }
      it 'should allow editing of name and description' do
        should have_tag("input#community_name")
        should have_tag("textarea#community_description")
      end
      it 'should allow inviting non-members to join community' do
        non_member = @test_data[:user_non_member]
        should have_tag(".edit_community fieldset") do
          with_tag("dt label", :text => "Invite Members")
          with_tag("input#invitations")
          fill_in 'invitations', :with => non_member.username
          click_button "save"
          should include("Community was successfully updated. An invitation was sent to")
        end
      end
    end
  end

  it 'should flash a link to become a curator, when a non-curator joins the curator community' do
    user = User.gen(:curator_level_id => nil)
    # TODO - for some odd reason, though the login works, the visit throws a "must be logged in" error. ...Perhaps
    # the session is clearing?
    login_as user
    visit(join_community_url(CuratorCommunity.get))
    page.should have_tag("a[href$='#{curation_privileges_user_path(user)}']")
  end

  it 'should not allow editing the name of the curator community' do
    manager = Member.create(:user => User.gen, :community => CuratorCommunity.get, :manager => true)
    # TODO - for some odd reason, though the login works, the visit throws a "must be logged in" error. ...Perhaps
    # the session is clearing?
    login_as manager.user
    visit(edit_community_url(CuratorCommunity.get))
    page.should have_tag("input#community_name[disabled=disabled]")
  end

end
