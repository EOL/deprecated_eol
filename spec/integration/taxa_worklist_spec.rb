require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Taxa worklist' do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :media_heavy
    @data = EOL::TestInfo.load('media_heavy')
    @taxon_concept = @data[:taxon_concept]
    Capybara.reset_sessions!
    CuratorLevel.create_defaults
    @curator = build_curator(@taxon_concept)
    @user = User.gen()
  end

  after(:each) do
    visit('/logout')
    Capybara.reset_sessions!
  end
  
  after(:all) do
    truncate_all_tables
  end

  it 'should available only for curators' do
    visit taxon_worklist_path(@taxon_concept)
    body.should_not have_tag("#worklist")
    login_as(@curator)
    visit taxon_worklist_path(@taxon_concept)
    body.should have_tag("#worklist")
    visit('/logout')
    login_as(@user)
    visit taxon_worklist_path(@taxon_concept)
    body.should_not have_tag("#worklist")
  end

  it 'should show filters, tasks list and selected task' do
    login_as(@curator)
    visit taxon_worklist_path(@taxon_concept)
    body.should have_tag('#worklist') do
      with_tag('.filters select')
      with_tag('#tasks ul')
      with_tag('#task')
    end
  end

  # TODO : This is not a good test but still I'm adding it for now. Review/modify it. Remove it if this test is not really necessary.
  it 'should show ratings, description, associations, revisions, source information sections selected task' do
    login_as(@curator)
    visit taxon_worklist_path(@taxon_concept)
    body.should have_tag('#worklist #task') do
      with_tag('.ratings .average_rating')
      with_tag('.article h3', :text => "Description")
      with_tag('.article .source h3', :text => "Source information")
      with_tag('.article form.review_status')
      with_tag('.article .list ul')
    end
  end

  it 'should be able to filter tasks'

  it 'should be able to rate active task'

  it 'should be able to curate an association for the active task'

  it 'should be able to add an association for the active task'

end