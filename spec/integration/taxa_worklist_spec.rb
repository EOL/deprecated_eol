require File.dirname(__FILE__) + '/../spec_helper'

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
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
    @taxon_concept.images_from_solr(100).last.data_objects_hierarchy_entries.first.update_attribute(:visibility_id, Visibility.invisible.id)
    @test_partner = ContentPartner.gen(:display_name => 'Media Light Partner')
    @test_resource = Resource.gen(:content_partner => @test_partner, :title => 'Media Light Resource')
    hevt = HarvestEvent.gen(:resource => @test_resource)
    image = @taxon_concept.images_from_solr.first
    DataObjectsHarvestEvent.connection.execute("UPDATE data_objects_harvest_events SET harvest_event_id=#{hevt.id} WHERE data_object_id=#{image.id}")
    DataObjectsHarvestEvent.connection.execute("COMMIT")
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end
  
  after(:all) do
    truncate_all_tables
  end
  
  before(:each) do
    login_as(@curator)
  end
  
  after(:each) do
    visit '/logout'
  end
  
  it 'should available only for full and master curators' do
    visit taxon_worklist_path(@taxon_concept)
    page.should have_selector('#worklist')
    
    visit('/logout')
    visit taxon_worklist_path(@taxon_concept)
    page.should_not have_selector('#worklist')
    
    login_as(@user)
    expect { visit taxon_worklist_path(@taxon_concept) }.to raise_error(EOL::Exceptions::SecurityViolation)
    
    assistant_curator = build_curator(@taxon_concept, :level=>:assistant)
    login_as(assistant_curator)
    expect { visit taxon_worklist_path(@taxon_concept) }.to raise_error(EOL::Exceptions::SecurityViolation)
  end
  
  it 'should show filters, tasks list and selected task' do
    visit taxon_worklist_path(@taxon_concept)
    page.should have_selector('#worklist .filters')
    page.should have_selector('#worklist .filters select#object_type')
    page.should have_selector('#worklist .filters select#object_status')
    page.should have_selector('#worklist .filters select#object_visibility')
    page.should have_selector('#worklist .filters select#task_status')
    page.should have_selector('#worklist .filters select#sort_by')
    page.should have_selector('#worklist .filters select#resource_id')
    
    page.should have_selector('#worklist_main_content')
    page.should have_selector('#worklist_main_content #tasks ul')
    page.should have_selector('#worklist_main_content #task')
  end
  
  it 'should show ratings, description, associations, revisions, source information sections selected task' do
    visit taxon_worklist_path(@taxon_concept)
    page.should have_selector('#worklist #task')
    page.should have_selector('#worklist #task .ratings .average_rating')
    page.should have_selector('#worklist #task .article.source h3', :text => 'Source information')
    page.should have_selector('#worklist #task .article form.review_status')
    page.should have_selector('#worklist #task .article.list ul')
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
    page.should have_content('50 tasks found')
    
    page.select("Text", :from => "object_type")
    click_button "show tasks"
    page.should have_content('6 tasks found')
    
    page.select("Video", :from => "object_type")
    click_button "show tasks"
    page.should have_content('8 tasks found')
    
    page.select("Sound", :from => "object_type")
    click_button "show tasks"
    page.should have_content('6 tasks found')
    
    page.select("Image", :from => "object_type")
    click_button "show tasks"
    page.should have_content('30 tasks found')
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
    page.should have_content('16 tasks found')
    
    page.select("Unreviewed", :from => "object_status")
    click_button "show tasks"
    page.should have_content('18 tasks found')
    
    page.select("Untrusted", :from => "object_status")
    click_button "show tasks"
    page.should have_content('16 tasks found')
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
    page.should have_content('49 tasks found')
    
    page.select("Hidden", :from => "object_visibility")
    click_button "show tasks"
    page.should have_content('1 task found')
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
    page.should have_content('50 tasks found')
    
    page.select("Test Framework Import (49)", :from => "resource_id")
    click_button "show tasks"
    page.should have_content('49 tasks found')
    page.select("Media Light Resource (1)", :from => "resource_id")
    click_button "show tasks"
    page.should have_content('1 task found')
  end
  
  it 'should be able to rate active task' do
    visit taxon_worklist_path(@taxon_concept)
    page.should have_selector('.ratings')
    page.should have_selector('.ratings .average_rating h5 small', :text => 'from 0 people')
    page.should have_selector('.ratings .average_rating .rating', :text => 'Average rating: 2.5 of 5')
    page.should have_selector('.ratings .rating h5', :text => 'Your rating')
    page.should have_selector('.rating ul .current_rating_0', :text => 'Your current rating: 0 of 5')
    
    click_link 'Change rating to 5 of 5'
    page.should have_selector('.ratings')
    page.should have_selector('.ratings .average_rating h5 small', :text => 'from 1 person')
    page.should have_selector('.ratings .average_rating .rating', :text => 'Average rating: 5.0 of 5')
    page.should have_selector('.ratings .rating h5', :text => 'Your rating')
    page.should have_selector('.rating ul .current_rating_5', :text => 'Your current rating: 5 of 5')
  end
  
  # it 'should be able to curate an association for the active task'
  # 
  # it 'should be able to add an association for the active task'

end
