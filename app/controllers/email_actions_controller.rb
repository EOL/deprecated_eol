class EmailActionsController < ApplicationController
  include PartnerUpdatesEmailer
  
  def sample
    activity = PartnerUpdatesEmailer.all_activity_since_hour(1500)
    pp activity
    
    ### Hard coded in the sample to be Brian Fisher for AntWeb
    # @agent_or_user = AgentContact.find(6)
    # @activity = activity[:partner_activity][6]
    
    @agent_or_user = User.find(40106)
    @activity = activity[:user_activity][40106]
    render :template => 'notifier/comments_and_actions_to_partner_or_user', :content_type => 'text/plain'
  end
  
  def send_emails
    parameter = SiteConfigurationOption.find_by_parameter('email_actions_to_curators')
    if parameter && parameter.value == 'true'
      PartnerUpdatesEmailer.send_email_updates
      render :text => "Emails sent"
    else
      render :text => "Not configured to send emails"
    end
  end
end
