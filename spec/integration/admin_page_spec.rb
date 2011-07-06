require File.dirname(__FILE__) + '/../spec_helper'

describe 'Admin Pages' do
  
  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @user = User.gen(:username => 'ourtestadmin')
    @user.approve_to_administrate
    
    @agent = Agent.gen(:full_name => 'HierarchyAgent')
    @hierarchy = Hierarchy.gen(:label => 'TreeofLife', :description => 'contains all life', :agent => @agent)
    @hierarchy_entry = HierarchyEntry.gen(:hierarchy => @hierarchy)
    
    last_month = Time.now - 1.month
    @report_year = last_month.year.to_s
    @report_month = last_month.month.to_s
    @year_month   = @report_year + "_" + "%02d" % @report_month.to_i
    @resource_user = User.gen(:agent => @agent)
    @content_parnter = ContentPartner.gen(:user => @resource_user)
    @resource = Resource.gen(:title => "FishBase Resource", :content_partner => @content_parnter)
    @harvest_event = HarvestEvent.gen(:resource_id => @resource.id, :published_at => last_month)
    
    @data_object = DataObject.gen(:published => 1, :vetted_id => Vetted.trusted.id)
    @data_objects_harvest_event = DataObjectsHarvestEvent.gen(:data_object_id => @data_object.id, :harvest_event_id => @harvest_event.id)
    
    @taxon_concept = TaxonConcept.gen(:published => 1, :supercedure_id => 0)
    @data_objects_taxon_concept = DataObjectsTaxonConcept.gen(:data_object_id => @data_object.id, :taxon_concept_id => @taxon_concept.id)
    
    @action_with_object = ActionWithObject.gen_if_not_exists(:action_code => 'trust')
    @changeable_object_type = ChangeableObjectType.gen()
    @action_history = ActionsHistory.gen(:object_id => @data_object.id, :action_with_object_id => @action_with_object.id, :changeable_object_type_id => @changeable_object_type.id)
    
    @toc_item = TocItem.gen_if_not_exists(:label => "sample label")
    @info_item = InfoItem.gen(:toc_id => @toc_item.id)
    
    @activity = Activity.gen(:name => "sample activity")
    @user_with_activity = User.gen(:given_name => "John", :family_name => "Doe")
    @activity_log = ActivityLog.gen(:user_id => @user_with_activity.id, :activity_id => @activity.id)
  end

  after :each do
    visit('/logout')
  end
  
  it 'should load the admin homepage' do
    login_as(@user)
    visit('/admin')
    body.should include('Welcome to the EOL Administration Console')
    body.should include('Site CMS')
    body.should include('News Items')
    body.should include('Comments and Tags')
    body.should include('Web Users')
    body.should include('Contact Us Functions')
    body.should include('Technical Functions')
    body.should include('Content Partners')
    body.should include('Statistics')
    body.should include('Data Usage Reports')
  end
  
  it 'should be able to load cms pages' do
    login_as(@user)
    visit('/administrator/content_page')
    body.should include('Add Page')
    body.should include('Create child page')
    body.should include('Add language')
    body.should include('Delete')
  end
  
  it 'should be able to load cms add page form' do
    login_as(@user)
    visit('/administrator/content_page/new')
    body.should include('Page Name')
    body.should include('Title')
    body.should include('Main content area')
  end
  
  it 'should show the list of hierarchies' do
    login_as(@user)
    visit('/administrator/hierarchy')
    body.should include(@agent.full_name)
    body.should include(@hierarchy.label)
    body.should include(@hierarchy.description)
  end
  
  it 'should be able to edit a hierarchy' do
    login_as(@user)
    visit("/administrator/hierarchy/edit/#{@hierarchy.id}")
    body.should include('<input id="hierarchy_label"')
    body.should include(@hierarchy.label)
    body.should include(@hierarchy.description)
  end
  
  it 'should be able to view a hierarchy' do
    login_as(@user)
    visit("/administrator/hierarchy/browse/#{@hierarchy.id}")
    body.should include(@hierarchy.label)
  end

  it 'should load an empty glossary page' do
    login_as(@user)
    visit('/administrator/glossary')
    body.should include("glossary is empty")
  end
  
  it 'should show glossary terms' do
    glossary_term = GlossaryTerm.gen(:term => 'Some new term', :definition => 'and its definition')
    login_as(@user)
    visit("/administrator/glossary")
    body.should include(glossary_term.term)
    body.should include(glossary_term.definition)
  end
  
  it 'should load an empty harvesting logs page' do
    login_as(@user)
    visit('/administrator/harvesting_log')
    body.should include("No harvesting logs")
  end
  
  it 'should show harvesting_logs' do
    harvest_process_log = HarvestProcessLog.gen(:process_name => 'Some test term that wont normally show up', :began_at => 1.day.ago)
    login_as(@user)
    visit('/administrator/harvesting_log')
    body.should include(harvest_process_log.process_name)
    body.should include(harvest_process_log.began_at.mysql_timestamp)
    
    visit('/administrator/harvesting_log?date=')
    body.should include(harvest_process_log.process_name)
    body.should include(harvest_process_log.began_at.mysql_timestamp)
    
    previous_day = 2.days.ago.strftime("%d-%b-%Y")
    visit('/administrator/harvesting_log?date=' + previous_day)
    body.should_not include(harvest_process_log.process_name)
    body.should include("No harvesting logs")
  end
  
  it "should show report_monthly_published_partners page" do
    login_as(@user)
    visit("/administrator/content_partner_report/report_monthly_published_partners")
    body.should include "New content partners for the month"
  end

  it "should get data from a form and display published partners" do
    login_as(@user)
    visit("/administrator/content_partner_report/report_monthly_published_partners", :method => :post, :params => {:year_month => @year_month}) 
    body.should have_tag("form[action=/administrator/content_partner_report/report_monthly_published_partners]")
    body.should include "New content partners for the month"
    body.should include @content_parnter.user.full_name
  end
  
  it "should show report_partner_curated_data page" do
    login_as(@user)
    visit("/administrator/content_partner_report/report_partner_curated_data")
    body.should include "Curation activity:"
  end

  it "should get data from a form and display curation activity" do
    login_as(@user)
    visit("/administrator/content_partner_report/report_partner_curated_data", :method => :post, :params => {:agent_id => @agent.id})  
    body.should have_tag("form[action=/administrator/content_partner_report/report_partner_curated_data]")
    body.should include "Curation activity:"
    body.should include @content_parnter.user.full_name
  end

  it "should get data from a form and display a month's curation activity" do
    login_as(@user)
    visit("/administrator/content_partner_report/report_partner_curated_data", :method => :post, :params => {:agent_id => @agent.id, :year_month => @year_month})  
    body.should have_tag("form[action=/administrator/content_partner_report/report_partner_curated_data]")
    body.should include "Curation activity:"
    body.should include @content_parnter.user.full_name
  end
  
  #TODO: report not working in master branch
  # it "should show report_partner_objects_stats page" do
  #   login_as(@user)
  #   visit("/administrator/content_partner_report/report_partner_objects_stats")
  #   body.should include "Viewing Partner:"
  # end
  # 
  # it "should get data from a form and display harvest events" do
  #   login_as(@user)
  #   visit("/administrator/content_partner_report/report_partner_objects_stats")
  #   select @agent.full_name, :from => "agent_id"
  #   click_button "Change"
  #   body.should have_tag("form[action=/administrator/content_partner_report/report_partner_objects_stats]")
  #   body.should include "Viewing Partner:"
  #   body.should include @agent.full_name
  #   body.should include @resource.title
  # end

  it "should link to data objects stats per harvest event" do
    login_as(@user)
    visit("/administrator/content_partner_report/show_data_object_stats?harvest_id=#{@harvest_event.id}&partner_fullname=#{URI.escape(@agent.full_name)}")
    body.should include "Total Data Objects:"
    body.should include @agent.full_name
    body.should include "#{@harvest_event.id}\n"
  end
  
  it "should show table of contents breakdown page" do
    login_as(@user)
    visit("/administrator/stats/toc_breakdown")
    body.should include "Table of Contents Breakdown"
    body.should include @toc_item.label
  end

  it "should get data from a form and display user activity" do
    login_as(@user)
    visit("/administrator/user/view_user_activity", :method => :post, :params => {:user_id => @user_with_activity.id})
    body.should have_tag("form[action=/administrator/user/view_user_activity]")
    body.should include "User Activity"
    body.should include @user_with_activity.family_name
    body.should include @activity.name
  end

  it "should list activity combinations in a 5-min. duration" do
    login_as(@user)
    visit("/administrator/user/view_common_combinations")
    body.should include "List of activity combinations in a 5-min. duration"
    body.should include @activity.name
  end

  it "should list activity combinations in a 5-min. duration for a given activity" do
    login_as(@user)
    visit("/administrator/user/view_common_combinations", :activity_id => @activity.id)
    body.should include "List of activity combinations in a 5-min. duration\nfor activity \n<b>\n#{@activity.name}\n</b>\n"
  end
end
