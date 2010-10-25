class EmailActionsController < ApplicationController
  include PartnerUpdatesEmailer
  
  def sample
    activity = PartnerUpdatesEmailer.all_activity_since_hour(1500)
    pp activity
    
    @agent_or_user = AgentContact.find(6)
    @activity = activity[:partner_activity][6]
    
    # @agent_or_user = User.find(25567)
    # @activity = activity[:user_activity][25567]
    render :template => 'notifier/comments_and_actions_to_partner_or_user', :content_type => 'text/plain'
  end
  
  def send_emails
    PartnerUpdatesEmailer.send_email_updates
    render :text => "Emails sent"
  end
end
