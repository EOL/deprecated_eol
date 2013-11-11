require File.dirname(__FILE__) + '/../../spec_helper'

def reset
  drop_all_virtuoso_graphs
  UserAddedData.destroy_all
  solr = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
  solr.obliterate
end

def add_data(options = {})
  # this sequence is tested in /integration/taxa_data_tab_spec.rb
  login_as @user
  visit(taxon_data_path(@taxon_concept))
  within(:xpath, '//form[@id="new_user_added_data"]') do
    fill_in 'user_added_data_predicate', :with => options[:attribute]
    fill_in 'user_added_data_object', :with => options[:value]
    click_button "submit data value"
  end
  sleep(1)
  UserAddedData.last
end

def hide_row
  visit(taxon_data_path(@taxon_concept))
  within(:xpath, "//div[a[@href='#{data_point_uri_hide_path(@user_added_data)}']]") do
    click_link "Hide Row"
    sleep(1)
  end
end

def unhide_row
  visit(taxon_data_path(@taxon_concept))
  within(:xpath, "//div[a[@href='#{data_point_uri_unhide_path(@user_added_data)}']]") do
    click_link "Unhide Row"
    sleep(1)
  end
end

def add_to_quick_facts
  visit(taxon_data_path(@taxon_concept))
  within(:xpath, "//div[a[@href='/taxon_data_exemplars?id=#{@user_added_data.id}&taxon_concept_id=#{@taxon_concept.id}']]") do
    click_link "add to Quick Facts"
    sleep(1)
  end
end

def remove_from_quick_facts
  visit(taxon_data_path(@taxon_concept))
  within(:xpath, "//div[a[@href='/#{taxon_data_exemplars_path(id: @user_added_data.id,
    taxon_concept_id: @taxon_concept.id, exclude: true)}']]") do
    click_link "remove Quick Facts"
  end
end

def comment(text)
  visit(taxon_data_path(@taxon_concept))
  within(:xpath, "//tr[@id='data_point_#{@user_added_data.id}']/following::tr") do
    fill_in 'comment_body', :with => text
    click_button "post annotation"
  end
end

describe 'DataPointUris' do
  before :all do
    load_foundation_cache
    SiteConfigurationOption.delete_all
    SiteConfigurationOption.create(parameter: 'all_users_can_see_data', value: '') 
    @parent_taxon_concept = build_taxon_concept
    @taxon_concept = build_taxon_concept(:parent_hierarchy_entry_id => @parent_taxon_concept.entry.id)
    @user = build_curator(@taxon_concept, :level => :master)
    @user.grant_permission(:see_data)
    @collection = @user.watch_collection
    @collection.add(@taxon_concept)
    flatten_hierarchies
  end

  shared_examples_for 'activity_logs check with permission' do
    before :all do
      visit logout_url
    end
    before :each do
      login_as @user
    end
    it 'should show activity on the homepage' do
      visit('/')
      body.should match @added_data_activity_regex
    end
    it 'should show activity on the taxon overview page' do
      visit(taxon_overview_path(@taxon_concept))
      body.should match @added_data_activity_regex
    end
    it 'should show activity on the taxon ancestors overview page' do
      visit(taxon_overview_path(@parent_taxon_concept))
      # Please figure out what the heck was happening here.  I suspect the SiteConfigurationOption is broken, but not sure.
      # save_and_open_page  should help
      debugger unless body =~ @added_data_activity_regex
      body.should match @added_data_activity_regex
    end
    it 'should show activity on the taxon updates page' do
      visit(taxon_updates_path(@taxon_concept))
      body.should match @added_data_activity_regex
    end
    it 'should show activity on the users activity page' do
      visit(user_activity_path(@user))
      body.should match @added_data_activity_regex
    end
    it 'should show activity in the newfeed of a containing collection' do
      visit(collection_newsfeed_path(@collection))
      body.should match @added_data_activity_regex
    end
  end

  shared_examples_for 'activity_logs check without permission' do
    before do
      visit logout_url
    end
    it 'should not show activity on the homepage' do
      visit('/')
      body.should_not match @added_data_activity_regex
    end
    it 'should not show activity on the taxon overview page' do
      visit(taxon_overview_path(@taxon_concept))
      debugger if body =~ @added_data_activity_regex
      body.should_not match @added_data_activity_regex
    end
    it 'should not show activity on the taxon ancestors overview page' do
      visit(taxon_overview_path(@parent_taxon_concept))
      debugger if body =~ @added_data_activity_regex
      body.should_not match @added_data_activity_regex
    end
    it 'should not show activity on the taxon updates page' do
      visit(taxon_updates_path(@taxon_concept))
      debugger if body =~ @added_data_activity_regex
      body.should_not match @added_data_activity_regex
    end
    it 'should not show activity on the users activity page' do
      visit(user_activity_path(@user))
      debugger if body =~ @added_data_activity_regex
      body.should_not match @added_data_activity_regex
    end
    it 'should not show activity in the newfeed of a containing collection' do
      visit(collection_newsfeed_path(@collection))
      debugger if body =~ @added_data_activity_regex
      body.should_not match @added_data_activity_regex
    end
  end

  describe 'adding data' do
    before :all do
      reset
      @user_added_data = add_data(
        attribute: Rails.configuration.schema_terms_prefix + 'added_predicate',
        value: 'Added Value')
      @added_data_activity_regex = /#{@user.full_name}.*added data to.*#{@taxon_concept.summary_name}.*Added Predicate.*Added Value/m
    end
    it_should_behave_like 'activity_logs check with permission'
    it_should_behave_like 'activity_logs check without permission'
  end

  describe 'hiding data' do
    before :all do
      reset
      @user_added_data = add_data(
        attribute: Rails.configuration.schema_terms_prefix + 'data_to_hide',
        value: 'Tohide Value')
      hide_row
      @added_data_activity_regex = /#{@user.full_name}.*chose to hide data on.*#{@taxon_concept.summary_name}.*Data To Hide.*Tohide Value/m
    end
    it_should_behave_like 'activity_logs check with permission'
    it_should_behave_like 'activity_logs check without permission'
  end

  describe 'unhiding data' do
    before :all do
      reset
      @user_added_data = add_data(
        attribute: Rails.configuration.schema_terms_prefix + 'data_to_unhide',
        value: 'Tounhide Value')
      hide_row
      unhide_row
      @added_data_activity_regex = /#{@user.full_name}.*chose to show data on.*#{@taxon_concept.summary_name}.*Data To Unhide.*Tounhide Value/m
    end
    it_should_behave_like 'activity_logs check with permission'
    it_should_behave_like 'activity_logs check without permission'
  end

  describe 'setting as exemplar' do
    before :all do
      reset
      @user_added_data = add_data(
        attribute: Rails.configuration.schema_terms_prefix + 'for_quick_facts',
        value: 'Tofacts Value')
      add_to_quick_facts
      @added_data_activity_regex = /#{@user.full_name}.*set data as exemplar on.*#{@taxon_concept.summary_name}.*For Quick Facts.*Tofacts Value/m
    end
    it_should_behave_like 'activity_logs check with permission'
    it_should_behave_like 'activity_logs check without permission'
  end

  describe 'commenting' do
    before :all do
      reset
      @user_added_data = add_data(
        attribute: Rails.configuration.schema_terms_prefix + 'for_comments',
        value: 'Tocomment Value')
      comment('testing annotations')
      @added_data_activity_regex = /#{@user.full_name}.*commented on.*data about.*#{@taxon_concept.summary_name}.*testing annotations/m
    end
    it_should_behave_like 'activity_logs check with permission'
    it_should_behave_like 'activity_logs check without permission'
 end
end
