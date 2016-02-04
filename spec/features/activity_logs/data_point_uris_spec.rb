# require "spec_helper"
# 
# def reset
  # drop_all_virtuoso_graphs
  # UserAddedData.destroy_all
  # solr = SolrAPI.new($SOLR_SERVER, $SOLR_ACTIVITY_LOGS_CORE)
  # solr.obliterate
# end
# 
# def add_data(options = {})
  # # this sequence is tested in /features/taxa_data_tab_spec.rb
  # login_as @user
  # visit(taxon_data_path(@taxon_concept))
  # within(:xpath, '//form[@id="new_user_added_data"]') do
    # fill_in 'user_added_data_predicate', with: options[:attribute]
    # fill_in 'user_added_data_object', with: options[:value]
    # click_button "submit data value"
  # end
  # sleep(1)
  # UserAddedData.last
# end
# 
# def hide_row
  # Rails.cache.clear
  # visit(taxon_data_path(@taxon_concept))
  # within("##{@user_added_data.data_point_uri.anchor}_actions") do
    # click_link "Hide Row"
    # sleep(1)
  # end
# end
# 
# def unhide_row
  # Rails.cache.clear
  # visit(taxon_data_path(@taxon_concept))
  # within("##{@user_added_data.data_point_uri.anchor}_actions") do
    # click_link "Unhide Row"
    # sleep(1)
  # end
# end
# 
# def add_to_quick_facts
  # Rails.cache.clear
  # visit(taxon_data_path(@taxon_concept))
  # within("##{@user_added_data.data_point_uri.anchor}_actions") do
    # click_link I18n.t(:data_row_add_exemplar_button)
    # sleep(1)
  # end
# end
# 
# def remove_from_quick_facts
  # visit(taxon_data_path(@taxon_concept))
  # within("##{@user_added_data.data_point_uri.anchor}_actions") do
    # click_link I18n.t(:data_row_remove_exemplar_button)
  # end
# end
# 
# def comment(text)
  # Rails.cache.clear
  # visit(taxon_data_path(@taxon_concept))
  # within(:xpath, "//tr[@id='data_point_#{@user_added_data.data_point_uri.id}']/following::tr") do
    # fill_in 'comment_body', with: text
    # click_button "post comment"
  # end
# end
# 
# describe 'DataPointUris' do
  # before :all do
    # load_foundation_cache
    # EolConfig.delete_all
    # EolConfig.create(parameter: 'all_users_can_see_data', value: '')
    # @parent_taxon_concept = build_taxon_concept(comments: [], toc: [], bhl: [], images: [], sounds: [], flash: [], youtube: [])
    # @taxon_concept = build_taxon_concept(parent_hierarchy_entry_id: @parent_taxon_concept.entry.id,
                                         # comments: [], toc: [], bhl: [], images: [], sounds: [], flash: [], youtube: [])
    # @user = build_curator(@taxon_concept, level: :master)
    # @user.grant_permission(:see_data)
    # @collection = @user.watch_collection
    # @collection.add(@taxon_concept)
    # EOL::Data.flatten_hierarchies
  # end
# 
  # def expect_data_feed(options = {})
    # expect(page).to have_tag('strong', text: @user.full_name)
    # expect(page).to have_tag('a', text: @taxon_concept.summary_name) unless options[:skip_taxon_link]
    # expect(page).to have_tag('p', text: data_activity_re)
    # expect(page).to have_tag('blockquote', text: data_details_re)
  # end
# 
  # shared_examples_for 'activity_logs check with permission' do
    # before :all do
      # visit logout_url
    # end
    # before :each do
      # login_as @user
    # end
    # it 'should show activity on the homepage' do
      # visit('/')
      # expect_data_feed(skip_taxon_link: true) # Not entirely sure why we don't link to the taxon on the homepage, but...
    # end
    # it 'should show activity on the taxon overview page' do
      # visit(taxon_overview_path(@taxon_concept))
      # expect_data_feed
    # end
    # it 'should show activity on the taxon ancestors overview page' do
      # visit(taxon_overview_path(@parent_taxon_concept))
      # expect_data_feed
    # end
    # it 'should show activity on the taxon updates page' do
      # visit(taxon_updates_path(@taxon_concept))
      # expect_data_feed
    # end
    # it 'should show activity on the users activity page' do
      # visit(user_activity_path(@user))
      # expect_data_feed
    # end
    # it 'should show activity in the newfeed of a containing collection' do
      # visit(collection_newsfeed_path(@collection))
      # expect_data_feed
    # end
  # end
# 
  # # NOTE - we don't check for the user/taxon values In the feed, because they might have been doing something else, elsewhere.
  # def expect_no_data_feed
    # # Test passes if there's no activity at all:
    # unless page.body =~ /#{I18n.t(:activity_log_empty)}/ or
           # page.body =~ /#{I18n.t(:no_record_found_matching_your_criteria)}/
      # if page.body =~ data_activity_re
        # save_and_open_page
        # debugger # This happens VERY rarely, and I can't imagine what's gone wrong. Last time it was on the taxon_updates page.
      # end
      # expect(page).to_not have_tag('p', text: data_activity_re)
      # expect(page).to_not have_tag('blockquote', text: data_details_re)
    # end
  # end
# 
  # # NOTE - visiting the logout_url before each visit was NOT working with seed=14397. (It's like the page was cached with the
  # # user's login... I wonder if it's failing to clear session data?) ...Anyway, re-writing it to # redirect after a logout worked
  # # fine.
  # shared_examples_for 'activity_logs check without permission' do
    # it 'should not show activity on the homepage' do
      # visit logout_url(return_to: '/')
      # expect_no_data_feed
    # end
    # it 'should not show activity on the taxon overview page' do
      # visit logout_url(return_to: taxon_overview_path(@taxon_concept))
      # expect_no_data_feed
    # end
    # it 'should not show activity on the taxon ancestors overview page' do
      # visit logout_url(return_to: taxon_overview_path(@parent_taxon_concept))
      # expect_no_data_feed
    # end
    # it 'should not show activity on the taxon updates page' do
      # visit logout_url(return_to: taxon_updates_path(@taxon_concept))
      # expect_no_data_feed
    # end
    # it 'should not show activity on the users activity page' do
      # visit logout_url(return_to: user_activity_path(@user))
      # expect_no_data_feed
    # end
    # it 'should not show activity in the newfeed of a containing collection' do
      # visit logout_url(return_to: collection_newsfeed_path(@collection))
      # expect_no_data_feed
    # end
  # end
# 
  # describe 'adding data' do
    # before :all do
      # reset
      # @user_added_data = add_data(
        # attribute: Rails.configuration.uri_term_prefix + 'added_predicate',
        # value: 'Added Value')
    # end
    # let(:data_activity_re) { /added data to/ }
    # let(:data_details_re) { /Added Predicate.*Added Value/m }
    # it_should_behave_like 'activity_logs check with permission'
    # it_should_behave_like 'activity_logs check without permission'
  # end
# 
  # describe 'hiding data' do
    # before :all do
      # reset
      # @user_added_data = add_data(
        # attribute: Rails.configuration.uri_term_prefix + 'data_to_hide',
        # value: 'Tohide Value')
      # hide_row
    # end
    # let(:data_activity_re) { /chose to hide data on/ }
    # let(:data_details_re) { /Data To Hide.*Tohide Value/m }
    # it_should_behave_like 'activity_logs check with permission'
    # it_should_behave_like 'activity_logs check without permission'
  # end
# 
  # describe 'unhiding data' do
    # before :all do
      # reset
      # @user_added_data = add_data(
        # attribute: Rails.configuration.uri_term_prefix + 'data_to_unhide',
        # value: 'Tounhide Value')
      # hide_row
      # unhide_row
    # end
    # let(:data_activity_re) { /chose to show data on/ }
    # let(:data_details_re) { /Data To Unhide.*Tounhide Value/m }
    # it_should_behave_like 'activity_logs check with permission'
    # it_should_behave_like 'activity_logs check without permission'
  # end
# 
  # describe 'setting as exemplar' do
    # before :all do
      # reset
      # @user_added_data = add_data(
        # attribute: Rails.configuration.uri_term_prefix + 'for_quick_facts',
        # value: 'Tofacts Value')
      # add_to_quick_facts
    # end
    # let(:data_activity_re) { /set data as exemplar on/ }
    # let(:data_details_re) { /For Quick Facts.*Tofacts Value/m }
    # it_should_behave_like 'activity_logs check with permission'
    # it_should_behave_like 'activity_logs check without permission'
  # end
# 
  # describe 'commenting' do
    # before :all do
      # reset
      # @user_added_data = add_data(
        # attribute: Rails.configuration.uri_term_prefix + 'for_comments',
        # value: 'Tocomment Value')
      # comment('testing annotations')
    # end
    # let(:data_activity_re) { /commented on.*data about/ }
    # let(:data_details_re) { /testing annotations/ }
    # it_should_behave_like 'activity_logs check with permission'
    # it_should_behave_like 'activity_logs check without permission'
 # end
# end
