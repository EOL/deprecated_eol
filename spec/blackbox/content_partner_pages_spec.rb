require File.dirname(__FILE__) + '/../spec_helper'

describe 'Content Partner Pages' do
  
  Scenario.load :foundation
  
  describe '(Reports)' do
    
    #TODO: do all this tests after fixing EOLINFRASTRUCTURE-1061   
      
    # before(:all) do
      # Scenario.load :foundation      
      
      # password = 'fumbletricket'
      # @content_partner  = Agent.gen(:hashed_password => 
      #                                Digest::MD5.hexdigest(password))
      # @cp               = ContentPartner.gen(:agent => @content_partner)
      # @taxon_concept    = build_taxon_concept(:agent => @content_partner)
      # @another_taxon_concept = build_taxon_concept
      # @user             = User.gen
      # @short_comment_from_user = 'Comment from user'
      # @curator          = build_curator(@taxon_concept)
      # @taxon_concept.images.first.comment(@user, @short_comment_from_user)
      # login_content_partner(:username => @content_partner.username,
      #                       :password => password)
      #                       debugger
      # @request          = request('/content_partner/reports')
    # end
    
    # Examples:
    #   Comment "This is a witty comment on the..." was changed to "hide" on "Animalia Linn." by e_howe25 1 day ago
    # OR
    #   Text for "Overview" on "Animalia Linn." was changed to "untrusted" by e_howe25 about 5 hours ago
    # OR
    #   Image on "Animalia Linn." was changed to "show" by e_howe25 about 5 hours ago
    
    # non logged in
    it 'should redirect from content_partner/reports to content_partner/reports/login if not logged in'
    
    #logged in as a content_partner
    
    #for every report
    it 'should only show activity for the content partner\'s clade'
    it 'should be "All changes", "Comments", "Statuses" items below "USAGE REPORTS" in TOC on content_partner/reports'
    it 'corresponding bullet should be blue if choose "All changes" / "Comments" / Statuses'
    it 'should have date in "human" format (e.g. "1 day ago")'
    it 'latest line should be above all'
    it 'name of Taxon_concept should be a link to Taxon_concept'
    it 'should have username of change\'s author'
    it 'username should be a link to account, if user is a curator'
    
    #for Comments report
    it 'should have title "Changing of comments"'
    it 'should have only lines started with "Comment..."'
    it 'should show text of comment'
    it 'should show entire short comment by user'
    it 'should show concatenated version of long comment (30 ch.)'
    it 'should show name of action ("created" or "changed to hide/show")'
    it 'should show name of Taxon_concept (= page name)'

    #for Statuses report
    it 'should have title "Changing of objects status"'
    it 'should have only lines started with "Text" or "Image"'
    it 'should be small picture in the next line after line "Image"'
    it '"Text" should have name of toc_label (e.g. Text for "Overview"...)'  
    it 'should show name of action ("changed to hide/show/trusted/untrusted/unupropiated")'
 
    # for All changes  
    it 'should have title "Changing of objects status and comments" on the center of a page'
    it 'should have all items from "Comments" and "Statuses" reports'
    it 'should have only items from "Comments" and "Statuses" reports'  
        
    #doesn't work for now, see EOLINFRASTRUCTURE-1061

    # it 'should show entire short comment by user' do
    #   @request.should include @short_comment_from_user
    # end
    # 
    
    # it 'should check if we come to /content_partner/reports and it has left-pane tag' do
    #   pass  = 'timey-wimey'
    #   agent = Agent.gen(:hashed_password => Digest::MD5.hexdigest(pass))
    #   cp    = ContentPartner.gen(:agent => agent)
    #   login_content_partner(:username => agent.username, :password => pass)
    #   body  = request('/content_partner/reports').body
    #   # debugger
    # 
    #   body.should have_tag('div#left-pane')
    # end

    # it 'should check if we come to /administrator/reports' do
    #   pass  = 'timey-wimey'
    #   user = User.gen(:hashed_password => Digest::MD5.hexdigest(pass))
    #   user.roles = Role.find(:all, :conditions => 'title LIKE "Admin%"')
    #   login_as(:username => user.username, :password => pass)
    #   body  = request('/administrator/reports').body
    #   debugger
    # 
    #   body.should have_tag('div')
    # end
    
    
    
  end
  
end

