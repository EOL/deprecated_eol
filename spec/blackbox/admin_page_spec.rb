require File.dirname(__FILE__) + '/../spec_helper'

describe 'Admin Pages' do
  
  before(:all) do
    truncate_all_tables
    Scenario.load('foundation')
    password = 'anypassword'
    @user = User.gen( :username => 'ourtestadmin',
                      :password => password,
                      :active => 1,
                      :hashed_password => Digest::MD5.hexdigest(password))
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
  
  
  
  
  
  
  
  
  
  
  
  it 'the remaining tests have been disabled in the interest of time.  Implement them later.'
#TEMP  Scenario.load :foundation
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
#TEMP     #        debugger
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
#TEMP  Scenario.load :foundation
#TEMP  
#TEMP  describe 'user/edit' do
#TEMP   it 'should have "Cc: affiliate@eol.org" in a head of an email from /administrator/user/edit/# page'
#TEMP  end
  
end
