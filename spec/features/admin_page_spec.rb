require "spec_helper"

describe 'Admin Pages' do

  before(:all) do
    load_foundation_cache
    Capybara.reset_sessions!
    @user = User.gen(username: 'ourtestadmin')
    @user.grant_admin

    @agent = Agent.gen(full_name: 'HierarchyAgent')
    @hierarchy = Hierarchy.gen(label: 'TreeofLife', description: 'contains all life', agent: @agent)
    @hierarchy_entry = HierarchyEntry.gen(hierarchy: @hierarchy)

    last_month = Time.now - 1.month
    @report_year = last_month.year.to_s
    @report_month = last_month.month.to_s
    @year_month   = @report_year + "_" + "%02d" % @report_month.to_i
    @resource_user = User.gen(agent: @agent)
    @content_partner = ContentPartner.gen(user: @resource_user)
    @resource = Resource.gen(title: "FishBase Resource", content_partner: @content_partner)
    @harvest_event = HarvestEvent.gen(resource_id: @resource.id, published_at: last_month)

    @data_object = build_data_object("Text", "This is a description", published: 1, vetted: Vetted.trusted)
    @data_objects_harvest_event = DataObjectsHarvestEvent.gen(data_object_id: @data_object.id, harvest_event_id: @harvest_event.id)

    @taxon_concept = TaxonConcept.gen(published: 1, supercedure_id: 0)
    @data_objects_taxon_concept = DataObjectsTaxonConcept.gen(data_object_id: @data_object.id, taxon_concept_id: @taxon_concept.id)

    @toc_item = TocItem.gen_if_not_exists(label: "sample label")
    @info_item = InfoItem.gen(toc_id: @toc_item.id)
  end

  after :each do
    visit('/logout')
  end

  it 'should load the admin homepage' do
    login_as(@user)
    visit('/administrator')
    page.should have_content('Welcome to the EOL Administration Console')
    page.should have_content('Site CMS')
    # TODO - This appears to have been removed... probably a merge error.
    # page.should have_content('News Items')
    page.should have_content('Comments and Tags')
    page.should have_content('Web Users')

    # commented in V2, until further notice
    #body.should include('Contact Us Functions')

    page.should have_content('Technical Functions')
    page.should have_content('Content Partners')
    page.should have_content('Statistics')
    page.should have_content('Data Usage Reports')
  end

  it 'should show the list of hierarchies' do
    login_as(@user)
    visit('/administrator/hierarchy')
    page.should have_content(@agent.full_name)
    page.should have_content(@hierarchy.label)
    page.should have_content(@hierarchy.description)
  end

  it 'should load an empty harvesting logs page' do
    login_as(@user)
    visit('/administrator/harvesting_log')
    page.should have_content("No harvesting logs")
  end

  it 'should show harvesting_logs' do
    harvest_process_log = HarvestProcessLog.gen(process_name: 'Some test term that wont normally show up', began_at: 1.day.ago)
    login_as(@user)
    visit('/administrator/harvesting_log')
    page.should have_content(harvest_process_log.process_name)
    page.should have_content(harvest_process_log.began_at.mysql_timestamp)

    # visit('/administrator/harvesting_log?date=')
    # page.should have_content(harvest_process_log.process_name)
    # page.should have_content(harvest_process_log.began_at.mysql_timestamp)

    previous_day = 2.days.ago.strftime("%d-%b-%Y")
    visit('/administrator/harvesting_log?date=' + previous_day)
    page.should_not have_content(harvest_process_log.process_name)
    page.should have_content("No harvesting logs")
    harvest_process_log.destroy
  end

  it "should show table of contents breakdown page" do
    login_as(@user)
    visit("/administrator/stats/toc_breakdown")
    page.should have_content("Table of Contents Breakdown")
    page.should have_content(@toc_item.label)
  end


end
