require "spec_helper"

describe 'Taxa worklist' do
  before(:all) do
    load_foundation_cache
    create_taxon_concept_with_media    
    Capybara.reset_sessions!
    CuratorLevel.create_enumerated
    @curator = build_curator(@taxon_concept) # build_curator generates a full curator by default.
    @user = User.gen()
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
    @taxon_concept.images_from_solr(100).last.data_objects_hierarchy_entries.first.update_attributes(visibility_id: Visibility.invisible.id)
    @test_partner = ContentPartner.gen(display_name: 'Media Light Partner')
    @test_resource = Resource.gen(content_partner: @test_partner, title: 'Media Light Resource')
    hevt = HarvestEvent.gen(resource: @test_resource)
    image = @taxon_concept.images_from_solr.first
    DataObjectsHarvestEvent.connection.execute("UPDATE data_objects_harvest_events SET harvest_event_id=#{hevt.id} WHERE data_object_id=#{image.id}")
    DataObjectsHarvestEvent.connection.execute("COMMIT")
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end
  
  def create_taxon_concept_with_media
    text = []
    images = []
    flash = []
    sounds = []
    youtube = []
    toc_items = [ TocItem.overview, TocItem.brief_summary]
    description = 'This is the text '
    10.times { images << { :data_rating => 1 + rand(5), :source_url => 'http://photosynth.net/identifying/by/string/is/bad/change/me' } }
    10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }
    10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.untrusted } }
    10.times { images << { :data_rating => 1 + rand(5), :vetted => Vetted.inappropriate } }
    2.times { text << { :toc_item => toc_items.sample, :description => description + rand(100).to_s } }
    2.times { text << { :toc_item => toc_items.sample, :vetted => Vetted.unknown, :description => description + rand(100).to_s } }
    2.times { text << { :toc_item => toc_items.sample, :vetted => Vetted.untrusted, :description => description + rand(100).to_s } }
    2.times { text << { :toc_item => toc_items.sample, :vetted => Vetted.inappropriate, :description => description + rand(100).to_s } }
    2.times { flash << { :data_rating => 1 + rand(5) } }
    2.times { flash << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }
    2.times { flash << { :data_rating => 1 + rand(5), :vetted => Vetted.untrusted } }
    2.times { flash << { :data_rating => 1 + rand(5), :vetted => Vetted.inappropriate } }
    2.times { sounds << { :data_rating => 1 + rand(5) } }
    2.times { sounds << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }
    2.times { sounds << { :data_rating => 1 + rand(5), :vetted => Vetted.untrusted } }
    2.times { sounds << { :data_rating => 1 + rand(5), :vetted => Vetted.inappropriate } }
    2.times { youtube << { :data_rating => 1 + rand(5), :vetted => Vetted.unknown } }
    @taxon_concept = build_taxon_concept(:canonical_form => 'Copious picturesqus', :common_names => [ 'Snappy' ],
                                             :images => images, :flash => flash, :sounds => sounds, :youtube => youtube,
                                             :toc => text, comments: [])
  end
  
  after(:all) do
    truncate_all_tables
  end
  
  before(:each) do
    UsersDataObjectsRating.delete_all()
    login_as(@curator)
  end
  
  after(:each) do
    visit '/logout'
  end
  
  it 'should available only for curators' do
    visit taxon_worklist_path(@taxon_concept)
    page.should have_selector('#worklist')
    
    visit('/logout')
    visit taxon_worklist_path(@taxon_concept)
    page.should_not have_selector('#worklist')
    
    login_as(@user)
    expect { visit taxon_worklist_path(@taxon_concept) }.to raise_error(EOL::Exceptions::SecurityViolation)
    
    assistant_curator = build_curator(@taxon_concept, level: :assistant)
    login_as(assistant_curator)
    expect { visit taxon_worklist_path(@taxon_concept) }.to_not raise_error
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
    body.should have_selector("#worklist #task .ratings dt", text: "default rating")
    page.should have_selector('#worklist #task .article.source h3', text: 'Source information')
    page.should have_selector('#worklist #task .article form.review_status')
    page.should have_selector('#worklist #task .article.list ul')
  end
  
  it 'should filter by data type' do
    visit taxon_worklist_path(@taxon_concept)
    page.select("All", from: "object_type")
    page.select("All", from: "object_status")
    page.select("All", from: "object_visibility")
    page.select("Active", from: "task_status")
    page.select("Newest", from: "sort_by")
    page.select("All", from: "resource_id")
    click_button "show tasks"
    page.should have_content('50 tasks found')
    
    page.select("Text", from: "object_type")
    click_button "show tasks"
    page.should have_content('6 tasks found')
    
    page.select("Video", from: "object_type")
    click_button "show tasks"
    page.should have_content('8 tasks found')
    
    page.select("Sound", from: "object_type")
    click_button "show tasks"
    page.should have_content('6 tasks found')
    
    page.select("Image", from: "object_type")
    click_button "show tasks"
    page.should have_content('30 tasks found')
  end
  
  it 'should filter by vetted status' do
    visit taxon_worklist_path(@taxon_concept)
    page.select("All", from: "object_type")
    page.select("Trusted", from: "object_status")
    page.select("All", from: "object_visibility")
    page.select("Active", from: "task_status")
    page.select("Newest", from: "sort_by")
    page.select("All", from: "resource_id")
    click_button "show tasks"
    page.should have_content('16 tasks found')
    
    page.select("Unreviewed", from: "object_status")
    click_button "show tasks"
    page.should have_content('18 tasks found')
    
    page.select("Untrusted", from: "object_status")
    click_button "show tasks"
    page.should have_content('16 tasks found')
  end
  
  it 'should filter by visibility' do
    visit taxon_worklist_path(@taxon_concept)
    page.select("All", from: "object_type")
    page.select("All", from: "object_status")
    page.select("Visible", from: "object_visibility")
    page.select("Active", from: "task_status")
    page.select("Newest", from: "sort_by")
    page.select("All", from: "resource_id")
    click_button "show tasks"
    page.should have_content('49 tasks found')
    
    page.select("Hidden", from: "object_visibility")
    click_button "show tasks"
    page.should have_content('1 task found')
  end
  
  it 'should filter by resource' do
    visit taxon_worklist_path(@taxon_concept)
    page.select("All", from: "object_type")
    page.select("All", from: "object_status")
    page.select("All", from: "object_visibility")
    page.select("Active", from: "task_status")
    page.select("Newest", from: "sort_by")
    page.select("All", from: "resource_id")
    click_button "show tasks"
    page.should have_content('50 tasks found')
    
    page.select("Test Framework Import (49)", from: "resource_id")
    click_button "show tasks"
    page.should have_content('49 tasks found')
    page.select("Media Light Resource (1)", from: "resource_id")
    click_button "show tasks"
    page.should have_content('1 task found')
  end
  
  it 'should be able to rate active task' do
    visit taxon_worklist_path(@taxon_concept)
    page.should have_selector('.ratings')
    body.should have_selector(".ratings dt", text: "default rating")
    page.should have_selector('.ratings .average_rating .rating', text: 'Default rating: 2.5 of 5')
    body.should have_selector(".ratings dt", text: "Your rating")
    page.should have_selector('.rating ul li.current_rating_0', text: 'Your current rating: 0 of 5')
    
    click_link 'Change rating to 5 of 5'
    page.should have_selector('.ratings')
    body.should have_selector(".ratings dt", text: "average rating")
    page.should have_selector('.ratings .average_rating .rating', text: 'Average rating: 5.0 of 5')
    body.should have_selector(".ratings dt", text: "Your rating")
    page.should have_selector('.rating ul li.current_rating_5', text: 'Your current rating: 5 of 5')
  end
  
  # it 'should be able to curate an association for the active task'
  # 
  # it 'should be able to add an association for the active task'

end
