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
    @curator = build_curator(@taxon_concept) # build_curator generates a full curator by default.
    @user = User.gen()
    SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE).delete_all_documents
    DataObject.all.each{ |d| d.update_solr_index }
    @taxon_concept.images_from_solr(100).last.data_objects_hierarchy_entries.first.update_attribute(:visibility_id, Visibility.invisible.id)
    @test_partner = ContentPartner.gen(:display_name => 'Media Light Partner')
    @test_resource = Resource.gen(:content_partner => @test_partner, :title => 'Media Light Resource')
    hevt = HarvestEvent.gen(:resource => @test_resource)
    image = @taxon_concept.images_from_solr.first
    DataObjectsHarvestEvent.connection.execute("UPDATE data_objects_harvest_events SET harvest_event_id=#{hevt.id} WHERE data_object_id=#{image.id}")
    DataObjectsHarvestEvent.connection.execute("COMMIT")
    DataObject.all.each{ |d| d.update_solr_index }
    login_as(@curator)
    visit taxon_worklist_path(@taxon_concept)
    @default_body = body
  end
  
  # after(:each) do
  #   visit('/logout')
  #   Capybara.reset_sessions!
  # end
  
  after(:all) do
    truncate_all_tables
  end
  
  it 'should available only for full and master curators' do
    @default_body.should have_tag("#worklist")
    visit('/logout')
    visit taxon_worklist_path(@taxon_concept)
    body.should_not have_tag("#worklist")
    login_as(@user)
    visit taxon_worklist_path(@taxon_concept)
    body.should_not have_tag("#worklist")
    assistant_curator = build_curator(@taxon_concept, :level=>:assistant)
    login_as(assistant_curator)
    visit taxon_worklist_path(@taxon_concept)
    body.should_not have_tag("#worklist")
    login_as(@curator)
  end
  
  it 'should show filters, tasks list and selected task' do
    @default_body.should have_tag('#worklist .filters') do
      with_tag('select#object_type')
      with_tag('select#object_status')
      with_tag('select#object_visibility')
      with_tag('select#task_status')
      with_tag('select#sort_by')
      with_tag('select#resource_id')
    end
    
    @default_body.should have_tag('#worklist_main_content') do
      with_tag('#tasks ul')
      with_tag('#task')
    end
  end
  
  # TODO : This is not a good test but still I'm adding it for now. Review/modify it. Remove it if this test is not really necessary.
  it 'should show ratings, description, associations, revisions, source information sections selected task' do
    @default_body.should have_tag('#worklist #task') do
      with_tag('.ratings .average_rating')
      with_tag('.article .source h3', :text => "Source information")
      with_tag('.article form.review_status')
      with_tag('.article .list ul')
    end
  end
  
  it 'should filter by data type' do
    visit taxon_worklist_path(@taxon_concept)
    page.select("All", :from => "object_type")
    page.select("All", :from => "object_status")
    page.select("All", :from => "object_visibility")
    page.select("Active", :from => "task_status")
    page.select("Newest", :from => "sort_by")
    page.select("All", :from => "resource_id")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '50 tasks found')
    
    page.select("Text", :from => "object_type")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '6 tasks found')
    
    page.select("Video", :from => "object_type")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '8 tasks found')
    
    page.select("Sound", :from => "object_type")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '6 tasks found')
    
    page.select("Image", :from => "object_type")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '30 tasks found')
  end
  
  it 'should filter by vetted status' do
    visit taxon_worklist_path(@taxon_concept)
    page.select("All", :from => "object_type")
    page.select("Trusted", :from => "object_status")
    page.select("All", :from => "object_visibility")
    page.select("Active", :from => "task_status")
    page.select("Newest", :from => "sort_by")
    page.select("All", :from => "resource_id")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '16 tasks found')
    
    page.select("Unreviewed", :from => "object_status")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '18 tasks found')
    
    page.select("Untrusted", :from => "object_status")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '16 tasks found')
  end
  
  it 'should filter by visibility' do
    visit taxon_worklist_path(@taxon_concept)
    page.select("All", :from => "object_type")
    page.select("All", :from => "object_status")
    page.select("Visible", :from => "object_visibility")
    page.select("Active", :from => "task_status")
    page.select("Newest", :from => "sort_by")
    page.select("All", :from => "resource_id")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '49 tasks found')
    
    page.select("Hidden", :from => "object_visibility")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '1 task found')
  end
  
  it 'should filter by resource' do
    visit taxon_worklist_path(@taxon_concept)
    page.select("All", :from => "object_type")
    page.select("All", :from => "object_status")
    page.select("All", :from => "object_visibility")
    page.select("Active", :from => "task_status")
    page.select("Newest", :from => "sort_by")
    page.select("All", :from => "resource_id")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '50 tasks found')
    
    page.select("Test Framework Import (49)", :from => "resource_id")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '49 tasks found')
    page.select("Media Light Resource (1)", :from => "resource_id")
    click_button "show tasks"
    body.should have_tag('.filters .actions', :text => '1 task found')
  end
  
  
  
  # 
  # it 'should be able to rate active task'
  # 
  # it 'should be able to curate an association for the active task'
  # 
  # it 'should be able to add an association for the active task'

end