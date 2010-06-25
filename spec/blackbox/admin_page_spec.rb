require File.dirname(__FILE__) + '/../spec_helper'

describe 'Admin Pages' do
  
  before(:all) do
    truncate_all_tables
    EolScenario.load('foundation')
    @user = User.gen(:username => 'ourtestadmin')
    @user.roles = Role.find(:all, :conditions => 'title LIKE "Admin%"')
    @user.save!
  end
  
  it 'should load the admin homepage' do
    login_as(@user).should redirect_to('/admin')
    body = request('/admin').body
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
  
  describe ': hierarchies' do
    before(:all) do
      @agent = Agent.gen(:full_name => 'HierarchyAgent')
      @hierarchy = Hierarchy.gen(:label => 'TreeofLife', :description => 'contains all life', :agent => @agent)
      @hierarchy_entry = HierarchyEntry.gen(:hierarchy => @hierarchy)
    end
    
    it 'should show the list of hierarchies' do
      login_as(@user).should redirect_to('/admin')
      body = request('/administrator/hierarchy').body
      body.should include(@agent.full_name)
      body.should include(@hierarchy.label)
      body.should include(@hierarchy.description)
    end
    
    it 'should be able to edit a hierarchy' do
      login_as(@user).should redirect_to('/admin')
      body = request("/administrator/hierarchy/edit/#{@hierarchy.id}").body
      body.should include('<input id="hierarchy_label"')
      body.should include(@hierarchy.label)
      body.should include(@hierarchy.description)
    end
    
    it 'should be able to view a hierarchy' do
      login_as(@user).should redirect_to('/admin')
      body = request("/administrator/hierarchy/browse/#{@hierarchy.id}").body
      body.should include(@hierarchy_entry.name_object.string)
    end
  end
  
  
  describe ': monthly published partners' do
    before(:all) do
      last_month = Time.now - 1.month      
      @report_year = last_month.year.to_s
      @report_month = last_month.month.to_s
      @year_month   = @report_year + "_" + "%02d" % @report_month.to_i      
      @agent = Agent.gen(:full_name => 'FishBase')
      @resource = Resource.gen(:title => "FishBase Resource")
      @agent_resource = AgentsResource.gen(:agent_id => @agent.id, :resource_id => @resource.id)
      @harvest_event = HarvestEvent.gen(:resource_id => @resource.id, :published_at => last_month)      
    end  
    it "should show report_monthly_published_partners page" do      
      login_as(@user).should redirect_to('/admin')      
      body = request("/administrator/content_partner_report/report_monthly_published_partners").body
      body.should include "New content partners for the month"
    end
    it "should get data from a form and display published partners" do          
      login_as(@user).should redirect_to('/admin')      
      res = request("/administrator/content_partner_report/report_monthly_published_partners", :method => :post, :params => {:year_month => @year_month})
      res.body.should have_tag("form[action=/administrator/content_partner_report/report_monthly_published_partners]")
      res.body.should include "New content partners for the month"
      res.body.should include @agent.full_name
    end
  end
  
  describe ': content partner curated data' do
    before(:all) do
      last_month = Time.now - 1.month      
      @report_year = last_month.year.to_s
      @report_month = last_month.month.to_s
      @year_month   = @report_year + "_" + "%02d" % @report_month.to_i      
      
      @agent = Agent.gen(:full_name => 'FishBase')
      @resource = Resource.gen(:title => "test resource")
      @agent_resource = AgentsResource.gen(:agent_id => @agent.id, :resource_id => @resource.id)
      last_month = Time.now - 1.month      
      @harvest_event = HarvestEvent.gen(:resource_id => @resource.id, :published_at => last_month)
      @data_object = DataObject.gen(:published => 1, :vetted_id => Vetted.trusted.id)
      @data_objects_harvest_event = DataObjectsHarvestEvent.gen(:data_object_id => @data_object.id, :harvest_event_id => @harvest_event.id)
      
      @taxon_concept = TaxonConcept.gen(:published => 1, :supercedure_id => 0)
      @data_objects_taxon_concept = DataObjectsTaxonConcept.gen(:data_object_id => @data_object.id, :taxon_concept_id => @taxon_concept.id)

      @action_with_object = ActionWithObject.gen()
      @changeable_object_type = ChangeableObjectType.gen()#id = 1 = data_object
      @action_history = ActionsHistory.gen(:object_id => @data_object.id, :action_with_object_id => @action_with_object.id, :changeable_object_type_id => @changeable_object_type.id)
     
    end  

    it "should show report_partner_curated_data page" do      
      login_as(@user).should redirect_to('/admin')      
      body = request("/administrator/content_partner_report/report_partner_curated_data").body
      body.should include "Curation activity:"
    end
    it "should get data from a form and display all curation activity" do          
      login_as(@user).should redirect_to('/admin')      
      res = request("/administrator/content_partner_report/report_partner_curated_data", :method => :post, :params => {:agent_id => @agent.id})
      res.body.should have_tag("form[action=/administrator/content_partner_report/report_partner_curated_data]")
      res.body.should include "Curation activity:"
      res.body.should include @agent.full_name      
    end
    it "should get data from a form and display a month's curation activity" do          
      login_as(@user).should redirect_to('/admin')      
      res = request("/administrator/content_partner_report/report_partner_curated_data", :method => :post, :params => {:agent_id => @agent.id, :year_month => @year_month})
      res.body.should have_tag("form[action=/administrator/content_partner_report/report_partner_curated_data]")
      res.body.should include "Curation activity:"
      res.body.should include @agent.full_name      
    end
  end      
  
  describe ': content partner objects stats' do
    before(:each) do
      last_month = Time.now - 1.month      
      @agent = Agent.gen(:full_name => 'FishBase')
      @resource = Resource.gen(:title => "FishBase Resource")
      @agent_resource = AgentsResource.gen(:agent_id => @agent.id, :resource_id => @resource.id)
      @harvest_event = HarvestEvent.gen(:resource_id => @resource.id, :published_at => last_month)
    end  
    it "should show report_partner_objects_stats page" do      
      login_as(@user).should redirect_to('/admin')      
      body = request("/administrator/content_partner_report/report_partner_objects_stats").body
      body.should include "Viewing Partner:"
    end
    it "should get data from a form and display harvest events" do          
      login_as(@user).should redirect_to('/admin')      
      res = request("/administrator/content_partner_report/report_partner_objects_stats", :method => :post, :params => {:agent_id => @agent.id})
      res.body.should have_tag("form[action=/administrator/content_partner_report/report_partner_objects_stats]")
      res.body.should include "Viewing Partner:"
      res.body.should include @agent.full_name
      res.body.should include @resource.title
    end
    it "should link to data objects stats per harvest event" do          
      login_as(@user).should redirect_to('/admin')      
      res = request("/administrator/content_partner_report/show_data_object_stats", :method => :post, :params => {:harvest_id => @harvest_event.id, :partner_fullname => "#{@agent.full_name}"})
      res.body.should include "Total Data Objects:"
      res.body.should include @agent.full_name
      res.body.should include "#{@harvest_event.id}\n"
    end
  end  

  #describe ': species profile model - objects count' do
  #  before(:all) do
  #    @info_item = InfoItem.gen() 
  #    @data_object = DataObject.gen(:published => 1, :vetted_id => Vetted.trusted.id)
  #    @data_objects_info_item = DataObjectsInfoItem.gen(:data_object_id => @data_object.id, :info_item_id => @info_item.id)
  #    @users_data_object = UsersDataObject.gen(:data_object_id => @data_object.id)
  #    @toc_item = TocItem.gen()  
  #    @data_objects_table_of_content = DataObjectsTableOfContent.gen(:data_object_id => @data_object.id, :toc_id => @toc_item.id)
  #  end  
  #  it "should show SPM_objects_count page" do      
  #    login_as(@user).should redirect_to('/admin')      
  #    body = request("/administrator/stats/SPM_objects_count").body
  #    body.should include "Species Profile Model - Data Objects Count"
  #    body.should include @info_item.schema_value
  #  end
  #end  

  #describe ': species profile model - partner count' do
  #  before(:all) do
  #    @info_item = InfoItem.gen() 
  #    @agent = Agent.gen(:full_name => 'FishBase')
  #    @resource = Resource.gen(:title => "test resource")
  #    @agent_resource = AgentsResource.gen(:agent_id => @agent.id, :resource_id => @resource.id)
  #    last_month = Time.now - 1.month      
  #    @harvest_event = HarvestEvent.gen(:resource_id => @resource.id, :published_at => last_month)
  #    @data_object = DataObject.gen(:published => 1, :vetted_id => Vetted.trusted.id)
  #    @data_objects_info_item = DataObjectsInfoItem.gen(:data_object_id => @data_object.id, :info_item_id => @info_item.id)
  #    @data_objects_harvest_event = DataObjectsHarvestEvent.gen(:data_object_id => @data_object.id, :harvest_event_id => @harvest_event.id)
  #  end  
  #  it "should show SPM_objects_count page" do      
  #    login_as(@user).should redirect_to('/admin')      
  #    body = request("/administrator/stats/SPM_partners_count").body
  #    body.should include "Species Profile Model - Content Partners Count"
  #    body.should include @info_item.schema_value
  #  end
  #end  

  describe ': table of contents breakdown' do
    before(:all) do      
    end  
    it "should show table of contents breakdown page" do      
      login_as(@user).should redirect_to('/admin')      
      body = request("/administrator/stats/toc_breakdown").body
      body.should include "Table of Contents Breakdown"
    end
  end  

  
  it 'the remaining tests have been disabled in the interest of time.  Implement them later.'
#TEMP  EolScenario.load :foundation
#TEMP  
#TEMP  describe '(Reports)' do
#TEMP    
#TEMP    #doesn't work for now, see EOLINFRASTRUCTURE-1061
#TEMP    
#TEMP     # it 'should check if we come to /administrator/reports' do
#TEMP     #        pass  = 'timey-wimey'
#TEMP     #        user = User.gen(:hashed_password => Digest::MD5.hexdigest(pass))
#TEMP     #        user.roles = Role.find(:all, :conditions => 'title LIKE "Admin%"')
#TEMP     #        login_as(:username => user.username, :password => pass)
#TEMP     #        body  = request('/administrator/reports').body
#TEMP     #      
#TEMP     #        body.should have_tag('div')
#TEMP     #  end
#TEMP    
#TEMP    # non logged in
#TEMP    it 'should redirect from administrator/reports/admin_whole_report to login if not logged in'
#TEMP    it 'should be text "Nothing To Report" below the title'
#TEMP    
#TEMP    #logged in as a admin
#TEMP    it 'should have date in "human" format (e.g. "1 day ago")'
#TEMP    it 'latest line should be above all'
#TEMP    it 'name of Taxon_concept should be a link to Taxon_concept'
#TEMP    it 'should have username of change\'s author'
#TEMP    it 'username should be a link to account, if user is a curator'
#TEMP    
#TEMP    #Comments lines
#TEMP    it 'lines should started with "Comment"'
#TEMP    it 'should show text of comment'
#TEMP    it 'should show entire short comment by user'
#TEMP    it 'should show concatenated version of long comment (~30 ch.)'
#TEMP    it 'should show name of action ("created" or "changed to hide/show")'
#TEMP    it 'should show name of Taxon_concept (= page name)'
#TEMP
#TEMP    #text or image changes lines
#TEMP    it 'lines should started with "Text" or "Image"'
#TEMP    it 'should be small picture in the next line after line "Image"'
#TEMP    it '"Text" should have name of toc_label (e.g. Text for "Overview"...)'  
#TEMP    it 'should show name of action ("changed to hide/show/trusted/untrusted/unupropiated")'
#TEMP 
#TEMP    # for All changes  
#TEMP    it 'should have title "Changing of objects status and comments" on the center of a page'
#TEMP    it 'should have all items from actions_histories table'
#TEMP        
#TEMP  end
#TEMP  
#TEMPend
#TEMP
#TEMPdescribe 'Administrator Web Users Pages' do
#TEMP  
#TEMP  EolScenario.load :foundation
#TEMP  
#TEMP  describe 'user/edit' do
#TEMP   it 'should have "Cc: affiliate@eol.org" in a head of an email from /administrator/user/edit/# page'
#TEMP  end
  
end
