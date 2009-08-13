require File.dirname(__FILE__) + '/../spec_helper'

describe 'Content Partner Pages' do
  
  Scenario.load :foundation
  
  describe '(Reports)' do
    
    #doesn't work for now, see EOLINFRASTRUCTURE-1061
    
     # it 'should check if we come to /administrator/reports' do
     #        pass  = 'timey-wimey'
     #        user = User.gen(:hashed_password => Digest::MD5.hexdigest(pass))
     #        user.roles = Role.find(:all, :conditions => 'title LIKE "Admin%"')
     #        login_as(:username => user.username, :password => pass)
     #        body  = request('/administrator/reports').body
     #        debugger
     #      
     #        body.should have_tag('div')
     #  end
    
    # non logged in
    it 'should redirect from administrator/reports/admin_whole_report to login if not logged in'
    it 'should be text "Nothing To Report" below the title'
    
    #logged in as a admin
    it 'should have date in "human" format (e.g. "1 day ago")'
    it 'latest line should be above all'
    it 'name of Taxon_concept should be a link to Taxon_concept'
    it 'should have username of change\'s author'
    it 'username should be a link to account, if user is a curator'
    
    #Comments lines
    it 'lines should started with "Comment"'
    it 'should show text of comment'
    it 'should show entire short comment by user'
    it 'should show concatenated version of long comment (~30 ch.)'
    it 'should show name of action ("created" or "changed to hide/show")'
    it 'should show name of Taxon_concept (= page name)'

    #text or image changes lines
    it 'lines should started with "Text" or "Image"'
    it 'should be small picture in the next line after line "Image"'
    it '"Text" should have name of toc_label (e.g. Text for "Overview"...)'  
    it 'should show name of action ("changed to hide/show/trusted/untrusted/unupropiated")'
 
    # for All changes  
    it 'should have title "Changing of objects status and comments" on the center of a page'
    it 'should have all items from actions_histories table'
        
  end
  
end

describe 'Administrator Web Users Pages' do
  
  Scenario.load :foundation
  
  describe 'user/edit' do
   it 'should have "Cc: affiliate@eol.org" in a head of an email from /administrator/user/edit/# page'
  end
  
end
