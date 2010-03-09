require File.dirname(__FILE__) + '/../spec_helper'

describe 'Content Partner Pages' do
  
  it 'ALL of these tests have been disabled in the interest of time.  Implement later.'

#TEMP  Scenario.load :foundation
#TEMP  
#TEMP  describe '(Reports)' do
#TEMP    
#TEMP    #TODO: do all this tests after fixing EOLINFRASTRUCTURE-1061   
#TEMP      
#TEMP    # before(:all) do
#TEMP      # Scenario.load :foundation      
#TEMP      
#TEMP      # password = 'fumbletricket'
#TEMP      # @content_partner  = Agent.gen(:hashed_password => 
#TEMP      #                                Digest::MD5.hexdigest(password))
#TEMP      # @cp               = ContentPartner.gen(:agent => @content_partner)
#TEMP      # @taxon_concept    = build_taxon_concept(:agent => @content_partner)
#TEMP      # @another_taxon_concept = build_taxon_concept
#TEMP      # @user             = User.gen
#TEMP      # @short_comment_from_user = 'Comment from user'
#TEMP      # @curator          = build_curator(@taxon_concept)
#TEMP      # @taxon_concept.images.first.comment(@user, @short_comment_from_user)
#TEMP      # login_content_partner(:username => @content_partner.username,
#TEMP      #                       :password => password)
#TEMP      #                       debugger
#TEMP      # @request          = request('/content_partner/reports')
#TEMP    # end
#TEMP    
#TEMP    # Examples:
#TEMP    #   Comment "This is a witty comment on the..." was changed to "hide" on "Animalia Linn." by e_howe25 1 day ago
#TEMP    # OR
#TEMP    #   Text for "Overview" on "Animalia Linn." was changed to "untrusted" by e_howe25 about 5 hours ago
#TEMP    # OR
#TEMP    #   Image on "Animalia Linn." was changed to "show" by e_howe25 about 5 hours ago
#TEMP    
#TEMP    # non logged in
#TEMP    it 'should redirect from content_partner/reports to content_partner/reports/login if not logged in'
#TEMP    
#TEMP    #logged in as a content_partner
#TEMP    
#TEMP    #for every report
#TEMP    it 'should only show activity for the content partner\'s clade'
#TEMP    it 'should be "All changes", "Comments", "Statuses" items below "USAGE REPORTS" in TOC on content_partner/reports'
#TEMP    it 'corresponding bullet should be blue if choose "All changes" / "Comments" / Statuses'
#TEMP    it 'should have date in "human" format (e.g. "1 day ago")'
#TEMP    it 'latest line should be above all'
#TEMP    it 'name of Taxon_concept should be a link to Taxon_concept'
#TEMP    it 'should have username of change\'s author'
#TEMP    it 'username should be a link to account, if user is a curator'
#TEMP    
#TEMP    #for Comments report
#TEMP    it 'should have title "Changing of comments"'
#TEMP    it 'should have only lines started with "Comment..."'
#TEMP    it 'should show text of comment'
#TEMP    it 'should show entire short comment by user'
#TEMP    it 'should show concatenated version of long comment (30 ch.)'
#TEMP    it 'should show name of action ("created" or "changed to hide/show")'
#TEMP    it 'should show name of Taxon_concept (= page name)'
#TEMP
#TEMP    #for Statuses report
#TEMP    it 'should have title "Changing of objects status"'
#TEMP    it 'should have only lines started with "Text" or "Image"'
#TEMP    it 'should be small picture in the next line after line "Image"'
#TEMP    it '"Text" should have name of toc_label (e.g. Text for "Overview"...)'  
#TEMP    it 'should show name of action ("changed to hide/show/trusted/untrusted/unupropiated")'
#TEMP 
#TEMP    # for All changes  
#TEMP    it 'should have title "Changing of objects status and comments" on the center of a page'
#TEMP    it 'should have all items from "Comments" and "Statuses" reports'
#TEMP    it 'should have only items from "Comments" and "Statuses" reports'  
#TEMP        
#TEMP    #doesn't work for now, see EOLINFRASTRUCTURE-1061
#TEMP
#TEMP    # it 'should show entire short comment by user' do
#TEMP    #   @request.should include @short_comment_from_user
#TEMP    # end
#TEMP    # 
#TEMP    
#TEMP    # it 'should check if we come to /content_partner/reports and it has left-pane tag' do
#TEMP    #   pass  = 'timey-wimey'
#TEMP    #   agent = Agent.gen(:hashed_password => Digest::MD5.hexdigest(pass))
#TEMP    #   cp    = ContentPartner.gen(:agent => agent)
#TEMP    #   login_content_partner(:username => agent.username, :password => pass)
#TEMP    #   body  = request('/content_partner/reports').body
#TEMP    #   # debugger
#TEMP    # 
#TEMP    #   body.should have_tag('div#left-pane')
#TEMP    # end
#TEMP
#TEMP    # it 'should check if we come to /administrator/reports' do
#TEMP    #   pass  = 'timey-wimey'
#TEMP    #   user = User.gen(:hashed_password => Digest::MD5.hexdigest(pass))
#TEMP    #   user.roles = Role.find(:all, :conditions => 'title LIKE "Admin%"')
#TEMP    #   login_as(:username => user.username, :password => pass)
#TEMP    #   body  = request('/administrator/reports').body
#TEMP    #   debugger
#TEMP    # 
#TEMP    #   body.should have_tag('div')
#TEMP    # end
#TEMP    
#TEMP    
#TEMP    
#TEMP  end
  
end

