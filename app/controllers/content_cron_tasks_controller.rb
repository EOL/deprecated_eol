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
    params[:hours] ||= 24
    params[:dont_send] ||= false
    @flickr_api = FlickrApi.new(:api_key => FLICKR_API_KEY, :secret => FLICKR_SECRET, :auth_token => FLICKR_TOKEN)
    comments = RecentContentCollector::flickr_comments(params[:hours])
    all_text = ""
    comments.each do |c|
      text = render_to_string(:template => "/content_cron_tasks/flickr_comment", :locals => {:comment => c})
      if text
        all_text += "#{c.visible_at} #{c.parent.flickr_photo_id}: #{text}\n\n<br\><br\>"
        unless params[:dont_send] || RAILS_ENV != 'production'
          @flickr_api.photos_add_comment(c.parent.flickr_photo_id, text)
        end
      end
    end
    render :text => "Comments sent to Flickr: #{all_text}"
  end

  def submit_flickr_curator_actions
    params[:hours] ||= 24
    params[:dont_send] ||= false
    @flickr_api = FlickrApi.new(:api_key => FLICKR_API_KEY, :secret => FLICKR_SECRET, :auth_token => FLICKR_TOKEN)
    curator_activity_logs = RecentContentCollector::flickr_curator_actions(params[:hours])
    all_text = ""
    curator_activity_logs.each do |ah|
      text = render_to_string(:template => "/content_cron_tasks/flickr_curator_action", :locals =>
                              {:curator_activity_log => ah})
      if text
        all_text += "#{ah.created_at} #{ah.data_object.flickr_photo_id}: #{text}\n\n<br\><br\>"
        unless params[:dont_send] || RAILS_ENV != 'production'
          @flickr_api.photos_add_comment(ah.data_object.flickr_photo_id, text)
        end
      end
    end
    render :text => "Curator Actions sent to Flickr: #{all_text}"
  end
end
