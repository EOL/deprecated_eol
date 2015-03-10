# encoding: utf-8
require "spec_helper"

def create_user username, password
  user = User.gen username: username, password: password
  user.password = password
  user.save!
  user
end

describe 'Users' do

  before(:all) do
    load_foundation_cache
    Capybara.reset_sessions!
    username = 'userprofilespec'
    password = 'beforeall'
    @user     = create_user(username, password)
    @watch_collection = @user.watch_collection
    @anon_user = User.gen(password: 'password')
  end

  after(:each) do
    @user.update_column(:language_id, Language.english.id)
    visit('/logout')
    I18n.locale = :en
  end

  it 'should generate api key' do
    login_as @user
    visit edit_user_path(@user)
    click_button 'Generate a key'
    body.should_not include("Generate a key")
    body.should have_selector('.requests dl') do |tags|
      tags.should have_selector('dt', text: 'API key')
      tags.should have_selector('dd textarea')
    end
  end

  it 'should change preferred language' do
    login_as @user
    body.should have_selector(".language p.en", text: "English")
    visit edit_user_path(@user)
    select "Français", from: "user_language_abbr"
    click_button I18n.t("helpers.submit.user.update")
    body.should have_selector(".language p.fr", text: "Français")
    visit edit_user_path(@user)
    select "English", from: "user_language_abbr"
    I18n.locale = :fr
    click_button I18n.t("helpers.submit.user.update")
    body.should have_selector(".language p.en", text: "English")
  end

  # TODO - we appear to be missing this checkbox.  ...Meaning, really: it's not there. I don't know if this is
  # desired or not.
  # it 'should toggle the checkbox to show news in preferred language' do
  #   login_as @user
  #   visit edit_user_path(@user)
  #   body.should_not have_selector("input[id=user_news_in_preferred_language][checked]")
  #   puts "what page are we on?"
  #   check "user_news_in_preferred_language"
  #   click_button "Save profile information"
  #   visit edit_user_path(@user)
  #   body.should have_selector("input[id=user_news_in_preferred_language][checked]")
  #   uncheck "user_news_in_preferred_language"
  #   click_button "Save profile information"
  #   visit edit_user_path(@user)
  #   body.should have_selector(".account .checkbox") do |tags|
  #     tags.should_not have_selector("input[id=user_news_in_preferred_language][checked]")
  #   end
  # end

  describe 'collections' do
    before(:each) do
      visit(user_collections_path(@user))
    end
    it 'should show their watch collection' do
      page.body.should match /#{Collection.find(@user.watch_collection).name}/
    end
  end

  describe 'my info' do
    before(:each) do
      visit(user_path(@user))
    end
    it "should have a 'My info' section"  do
      body.should have_selector("h3", text: "My info")
      body.should have_selector(".info") do |tags|
        tags.should have_selector('dd', text: @user.full_name)
        tags.should have_selector('dd', text: @user.username)
      end
      #TODO - add more tests for 'My info' section
    end
    it "should not see Curator qualifications section if user is not curator" do
      if !@user.is_curator?
        body.should_not include("Curator qualifications")
      end
    end
    it "should not see curation activities in the Activity section if user is not curator" do
      user = User.gen(curator_level_id: nil)
      visit(user_path(user))
      body.should_not have_selector("a[href='" + user_activity_path(user, filter: "data_object_curation") + "']")
      body.should_not include("preferred classification")
      body.should_not have_selector("a[href='" + user_activity_path(user, filter: "names") + "']")
      body.should have_selector("a[href='" + user_activity_path(user, filter: "taxa_comments") + "']")
      body.should have_selector("a[href='" + user_activity_path(user, filter: "comments") + "']")
      body.should have_selector("a[href='" + user_activity_path(user, filter: "added_data_objects") + "']")
    end
    it "should see curation activities in the Activity section only if user is curator" do
      tc = build_taxon_concept(images: [{}], comments: [], bhl: [], sounds: [], toc: [], youtube: [], flash: [])
      curator = build_curator(tc)
      udo = UsersDataObject.gen(user_id: curator.id, taxon_concept: tc, visibility_id: Visibility.visible.id)
      user_submitted_text_count = UsersDataObject.count(conditions: ['user_id = ?', curator.id])
      object = tc.data_objects.first
      cal = CuratorActivityLog.gen(user_id: curator.id, taxon_concept: tc, target_id: object.id, activity_id: Activity.trusted.id, changeable_object_type_id: ChangeableObjectType.find_by_ch_object_type('data_object').id)
      
      ctcpe = CuratedTaxonConceptPreferredEntry.create(taxon_concept_id: tc.id, hierarchy_entry_id: tc.entry.id, user_id: curator.id)
      cot = ChangeableObjectType.gen_if_not_exists(ch_object_type: 'curated_taxon_concept_preferred_entry')
      CuratorActivityLog.create(user: curator, changeable_object_type: cot,
        target_id: ctcpe.id, hierarchy_entry_id: tc.entry.id, taxon_concept_id: tc.id,
        activity: Activity.preferred_classification)
      visit(user_path(curator))
      body.should have_selector("h3", text: "Activity")
      body.should have_selector("h3", text: "Curator qualifications")
      body.should have_selector("a[href='" + user_activity_path(curator, filter: "data_object_curation") + "']",
                                text: I18n.t(:user_activity_stats_objects_curated,
                                                   count: Curator.total_objects_curated_by_action_and_user(nil,
                                                                                                        curator.id)))
      body.should include(I18n.t(:user_activity_stats_preferred_classifications_selected, 
        count: Curator.total_objects_curated_by_action_and_user(Activity.preferred_classification.id,
        curator.id, [ChangeableObjectType.curated_taxon_concept_preferred_entry.id])))
      body.should include I18n.t(:user_activity_stats_taxa_curated, count: curator.total_species_curated)
      body.should have_selector("a[href='" + user_activity_path(curator, filter: "names") + "']")
      body.should have_selector("a[href='" + user_activity_path(curator, filter: "taxa_comments") + "']")
      body.should have_selector("a[href='" + user_activity_path(curator, filter: "comments") + "']")
      body.should have_selector("a[href='" + user_activity_path(curator, filter: "added_data_objects") + "']", text: I18n.t(:user_activity_stats_articles_added, count: user_submitted_text_count))
    end
  end

  describe 'my activity' do
    it "should have a form with dropdown filter element" do
      visit(user_activity_path(@user))
      body.should include "My activity"
      body.should have_selector "form.filter" do |tags|
        tags.should have_selector("select[name=filter]")
      end
      ["All", "Comments", "Objects curated", "Articles added", "Data added", "Collections", "Communities"].each_with_index do |filt,i|
        find(:xpath, "//option[#{i+1}]").text.should == filt
      end
    end
    it "should get data from a form and display accordingly" do
      visit(user_activity_path(@user, filter: "comments"))
      body.should have_selector("option[value=comments][selected=selected]")
      visit(user_activity_path(@user, filter: "data_object_curation"))
      body.should have_selector("option[value=data_object_curation][selected=selected]")
      visit(user_activity_path(@user, filter: "added_data_objects"))
      body.should have_selector("option[value=added_data_objects][selected=selected]")
      visit(user_activity_path(@user, filter: "collections"))
      body.should have_selector("option[value=collections][selected=selected]")
      visit(user_activity_path(@user, filter: "communities"))
      body.should have_selector("option[value=communities][selected=selected]")
      visit(user_activity_path(@user, filter: "added_data"))
      body.should have_selector("option[value=added_data][selected=selected]")
    end
  end

  describe 'newsfeed' do
    it 'should show a newsfeed'
    it 'should allow comments to be added' do
      visit logout_url
      visit user_newsfeed_path(@user)
      page.fill_in 'comment_body', with: "#{@anon_user.username} woz 'ere #{generate(:string)}"
      click_button 'Post Comment'
      page.fill_in 'session_username_or_email', with: @anon_user.username
      page.fill_in 'session_password', with: 'password'
      click_button 'Sign in'
      current_url.should match /#{user_path(@user)}/
      body.should include('Comment successfully added')
      Comment.last.body.should match /#{@anon_user.username}/

      visit user_newsfeed_path(@user)
      page.fill_in 'comment_body', with: "#{@user.username} woz 'ere #{generate(:string)}"
      click_button 'Post Comment'
      body.should include('Comment successfully added')
      Comment.last.body.should match /#{@user.username}/

      # test error handling when body is empty
      click_button 'Post Comment'
      body.should include('comment could not be added')
      visit logout_url
    end
    it 'should auto submit comment, posted before login, after user then logs in with Facebook'
    # TODO: Tried to do this but Web mock wasn't stubbing request and redirects weren't being followed!?
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
