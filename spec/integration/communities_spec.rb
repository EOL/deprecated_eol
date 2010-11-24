require File.dirname(__FILE__) + '/../spec_helper'

describe "Communities" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @community = Community.gen
    @user1 = User.gen # It's important that user1 NOT be a member of community2
    @user2 = User.gen
    @community.add_member(@user1)
    @community.add_member(@user2)
    @community2 = Community.gen # It's important that user1 NOT be a member of community2
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

    it 'should ask for the new community name and description' do
      visit new_community_path
      page.body.should have_tag("input#community_name")
      page.body.should have_tag("textarea#community_description")
    end

    it 'should create a community and redirect to show on create' do
      visit new_community_path
      fill_in('community_name', :with => 'Some New Name')
      fill_in('community_description', :with => 'This is a long decription.')
      click_button('Create')
      current_path.should == community_path(Community.last)
    end

  end

  describe '#show' do

    it 'should show the community name and description' do
      visit community_path(@community)
      page.should have_content(@community.name)
      page.should have_content(@community.description)
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

    it 'should show log in message when not logged in' do
      visit community_path(@community)
      page.body.should have_tag("#full-page-content") do # Make sure we're not looking at the header.
        with_tag("a[href=#{login_path}]")
      end
    end

    describe '(with member logged in)' do

      before(:each) do
        login_capybara @user1
      end

      after(:each) do
        visit(logout_url)
      end

      it 'should show join link and NOT edit or delete links when logged-in user is NOT a member' do
        visit community_path(@community2)
        page.body.should have_tag("a[href=#{join_community_path(:community_id => @community2.id)}]")
        page.body.should_not have_tag("a[href=#{edit_community_path(@community)}]")
        page.body.should_not have_tag("a[href=#{community_path(@community)}]", :text => /delete/i)
      end

      it 'should show leave link' do
        visit community_path(@community)
        page.body.should have_tag("a[href=#{leave_community_path(:community_id => @community.id)}]")
      end

      it 'should show edit and delete links' do
        visit community_path(@community)
        page.body.should have_tag("a[href=#{edit_community_path(@community)}]")
        page.body.should have_tag("a[href=#{community_path(@community)}]", :text => /delete/i)
      end

      it 'should NOT show logged-in message' do
        visit community_path(@community)
        page.body.should_not have_tag("a[href=#{login_path}]", :text => /must be logged in/)
      end

    end

  end

  describe '#edit' do

    it 'should not allow non-members'

    it 'should allow editing of name and description' do
      login_capybara @user1
      visit edit_community_path(@community)
      page.body.should have_tag("input#community_name")
      page.body.should have_tag("textarea#community_description")
    end

  end

  it 'should allow non-members to join communities, then redirect to show' do
    login_capybara @user1
    @user1.member_of?(@community2).should_not be_true
    visit(join_community_path(:community_id => @community2.id))
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
    login_capybara @user1
    @user1.member_of?(@community).should be_true
    visit(leave_community_path(:community_id => @community.id))
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
