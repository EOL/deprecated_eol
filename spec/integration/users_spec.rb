require File.dirname(__FILE__) + '/../spec_helper'

def create_user username, password
  user = User.gen :username => username, :password => password
  user.password = password
  user.save!
  user
end

describe 'Users' do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    username = 'userprofilespec'
    password = 'beforeall'
    @user     = create_user(username, password)
    @watch_collection = @user.watch_collection
    @anon_user = User.gen(:password => 'password')
  end

  after(:each) do
    visit('/logout')
  end

  it 'should generate api key' do
   login_as @user
   visit edit_user_path(@user)
   click_button 'Generate a key'
   body.should_not include("Generate a key")
   body.should have_tag('.requests dl') do
     with_tag('dt', 'API key')
     with_tag('dd textarea')
   end
 end

  describe 'collections' do
    before(:each) do
      visit(user_collections_path(@user))
    end
    it 'should show their watch collection' do
      page.body.should have_tag('#profile_collections', /#{@watch_collection.name}/)
    end
  end

  describe 'my info' do
    before(:each) do
      visit(user_path(@user))
    end
    it "should have a 'My info' section"  do
      body.should have_tag("h3", :text => "My info")
      body.should have_tag(".info") do
        with_tag('dt', 'Full name')
        with_tag('dd', @user.full_name)
        with_tag('dt', 'Username')
        with_tag('dd', @user.username)
      end
      #TODO - add more tests for 'My info' section
    end
    it "should not see Curator qualifications section if user is not curator" do
      if !@user.is_curator?
        body.should_not have_tag("h3", :text => "Curator qualifications")
      end
    end
    it "should see Activity section only if user is curator" do
      # Create a user which is a curator to enable Activity section
      tc = TaxonConcept.gen()
      user = build_curator(tc)
      # User added an article
      udo = UsersDataObject.gen(:user_id => user.id, :taxon_concept => tc, :visibility_id => Visibility.visible.id)
      user_submitted_text_count = UsersDataObject.count(:conditions => ['user_id = ?', user.id])
      # Curator activity log
      object = DataObject.gen
      cal = CuratorActivityLog.gen(:user_id => user.id, :taxon_concept => tc, :object_id => object.id, :activity_id => Activity.trusted.id, :changeable_object_type_id => ChangeableObjectType.find_by_ch_object_type('data_object').id)
      dotc = DataObjectsTaxonConcept.gen(:data_object => object, :taxon_concept => tc)
      visit(user_path(user))
      body.should have_tag("h3", :text => "Activity")
      body.should have_tag("h3", :text => "Curator qualifications")
      body.should have_tag("a[href=" + user_activity_path(user, :filter => "data_object_curation") + "]", :text => I18n.t(:user_activity_stats_objects_curated, :count => User.total_objects_curated_by_action_and_user(nil, user.id)))
      body.should have_tag("a[href=" + user_activity_path(user, :filter => "added_data_objects") + "]", :text => I18n.t(:user_activity_stats_articles_added, :count => user_submitted_text_count))
      body.should include I18n.t(:user_activity_stats_taxa_curated, :count => user.total_species_curated)
    end
  end

  describe 'my activity' do
    it "should have a form with dropdown filter element" do
      visit(user_activity_path(@user))
      body.should include "My activity"
      body.should have_tag "form.filter" do
        with_tag "select[name=filter]"
      end
      body.should have_tag("option:nth-child(1)", :text => "All")
      body.should have_tag("option:nth-child(2)", :text => "Comments")
      body.should have_tag("option:nth-child(3)", :text => "Objects curated")
      body.should have_tag("option:nth-child(4)", :text => "Articles added")
      body.should have_tag("option:nth-child(5)", :text => "Collections")
      body.should have_tag("option:nth-child(6)", :text => "Communities")
    end
    it "should get data from a form and display accordingly" do
      visit(user_activity_path(@user, :filter => "comments"))
      body.should have_tag("option[value=comments][selected=selected]")
      visit(user_activity_path(@user, :filter => "data_object_curation"))
      body.should have_tag("option[value=data_object_curation][selected=selected]")
      visit(user_activity_path(@user, :filter => "added_data_objects"))
      body.should have_tag("option[value=added_data_objects][selected=selected]")
      visit(user_activity_path(@user, :filter => "collections"))
      body.should have_tag("option[value=collections][selected=selected]")
      visit(user_activity_path(@user, :filter => "communities"))
      body.should have_tag("option[value=communities][selected=selected]")
    end
  end

  describe 'newsfeed' do
    it 'should show a newsfeed'
    it 'should allow comments to be added' do
      visit logout_url
      visit user_newsfeed_path(@user)
      page.fill_in 'comment_body', :with => "#{@anon_user.username} woz 'ere"
      click_button 'Post Comment'
      if current_url.match /#{login_url}/
        page.fill_in 'session_username_or_email', :with => @anon_user.username
        page.fill_in 'session_password', :with => 'password'
        click_button 'Sign in'
      end
      current_url.should match /#{user_path(@user)}/
      body.should include('Comment successfully added')
      Comment.last.body.should match /#{@anon_user.username}/

      visit user_newsfeed_path(@user)
      page.fill_in 'comment_body', :with => "#{@user.username} woz 'ere"
      click_button 'Post Comment'
      body.should include('Comment successfully added')
      Comment.last.body.should match /#{@user.username}/

      # test error handling when body is empty
      click_button 'Post Comment'
      body.should include('comment could not be added')
      visit logout_url
    end
  end

  it 'should not show a newsfeed, info, activity, collections, communities, content partners of a deactivated user' do
    @user.active = false
    @user.save!
    visit user_newsfeed_path(@user)
    body.should include('This user is no longer active')
    visit(user_path(@user))
    body.should include('This user is no longer active')
    visit(user_activity_path(@user))
    body.should include('This user is no longer active')
    visit(user_collections_path(@user))
    body.should include('This user is no longer active')
    visit(user_communities_path(@user))
    body.should include('This user is no longer active')
    visit(user_content_partners_path(@user))
    body.should include('This user is no longer active')
    @user.active = true
    @user.save!
  end
  
end
