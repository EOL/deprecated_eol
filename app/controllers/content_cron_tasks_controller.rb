require 'recent_content_collector'
require 'partner_updates_emailer'

class ContentCronTasksController < ApplicationController

  def send_curator_action_emails
    parameter = SiteConfigurationOption.find_by_parameter('email_actions_to_curators')
    if parameter && parameter.value == 'true'
      PartnerUpdatesEmailer.send_email_updates
      render :text => "Emails sent"
    else
      render :text => "Not configured to send emails"
    end
  end

  def submit_flickr_comments
    @flickr_api = FlickrApi.new(:api_key => FLICKR_API_KEY, :secret => FLICKR_SECRET, :auth_token => FLICKR_TOKEN)
    comments = RecentContentCollector::flickr_comments(24)
    comments.each do |c|
      text = render_to_string(:template => "/content_cron_tasks/flickr_comment", :locals => {:comment => c})
      if text
        @flickr_api.photos_add_comment(c.parent.flickr_photo_id, text)
      end
    end
    render :text => "Comments sent to Flickr"
  end

  def submit_flickr_curator_actions
    @flickr_api = FlickrApi.new(:api_key => FLICKR_API_KEY, :secret => FLICKR_SECRET, :auth_token => FLICKR_TOKEN)
    curator_activity_logs = RecentContentCollector::flickr_curator_actions(24)
    curator_activity_logs.each do |ah|
      text = render_to_string(:template => "/content_cron_tasks/flickr_curator_action", :locals =>
                              {:curator_activity_log => ah})
      if text
        @flickr_api.photos_add_comment(ah.data_object.flickr_photo_id, text)
      end
    end
    render :text => "Curator Actions sent to Flickr"
  end
end
