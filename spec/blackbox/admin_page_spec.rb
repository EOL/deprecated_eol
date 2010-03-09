require File.dirname(__FILE__) + '/../spec_helper'

describe 'Content Partner Pages' do

  it 'ALL of these tests have been disabled in the interest of time.  Implement them later.'
  
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
