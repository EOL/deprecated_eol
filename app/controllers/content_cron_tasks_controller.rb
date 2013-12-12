require 'recent_content_collector'
require 'partner_updates_emailer'

class ContentCronTasksController < ApplicationController

  def send_curator_action_emails
    # parameter = EolConfig.find_by_parameter('email_actions_to_curators')
    # if parameter && parameter.value == 'true'
    #   PartnerUpdatesEmailer.send_email_updates
    #   render text: "Emails sent"
    # else
    #   render text: "Not configured to send emails"
    # end
    render text: "Not configured to send emails"
  end

  def submit_flickr_comments
    params[:hours] ||= 24
    params[:dont_send] ||= false
    @flickr_api = FlickrApi.new(api_key: FLICKR_API_KEY, secret: FLICKR_SECRET, auth_token: FLICKR_TOKEN)
    comments = RecentContentCollector::flickr_comments(params[:hours])
    all_text = ""
    comments.each do |c|
      next if c.deleted?
      text = render_to_string(template: "/content_cron_tasks/flickr_comment", locals: {comment: c})
      if text
        all_text += "#{c.visible_at} #{c.parent.flickr_photo_id}: #{text}\n\n<br\><br\>"
        if params[:dont_send] || !Rails.env.production?
          # Do nothing; either we asked not to send it, or we're not in production (and thus don't want to send data)
        else
          @flickr_api.photos_add_comment(c.parent.flickr_photo_id, text)
        end
      end
    end
    render text: "Comments sent to Flickr: #{all_text}"
  end

  def submit_flickr_curator_actions
    params[:hours] ||= 24
    params[:dont_send] ||= false
    @flickr_api = FlickrApi.new(api_key: FLICKR_API_KEY, secret: FLICKR_SECRET, auth_token: FLICKR_TOKEN)
    curator_activity_logs = RecentContentCollector::flickr_curator_actions(params[:hours])
    all_text = ""
    curator_activity_logs.each do |ah|
      text = render_to_string(template: "/content_cron_tasks/flickr_curator_action", :locals =>
                              {curator_activity_log: ah})
      if text
        all_text += "#{ah.created_at} #{ah.data_object.flickr_photo_id}: #{text}\n\n<br\><br\>"
        if params[:dont_send] || !Rails.env.production?
          # Do nothing; either we asked not to send it, or we're not in production (and thus don't want to send data)
        else
          @flickr_api.photos_add_comment(ah.data_object.flickr_photo_id, text)
        end
      end
    end
    render text: "Curator Actions sent to Flickr: #{all_text}"
  end
  
  def send_monthly_partner_stats_notification
    last_month = Date.today - 1.month
    if !GoogleAnalyticsPageStat.find(:first, conditions: ['year = :year AND month = :month', {year: last_month.year, month: last_month.month}]) ||
       !GoogleAnalyticsPartnerTaxon.find(:first, conditions: ['year = :year AND month = :month', {year: last_month.year, month: last_month.month}]) ||
       !GoogleAnalyticsSummary.find(:first, conditions: ['year = :year AND month = :month', {year: last_month.year, month: last_month.month}])
      render text: "Monthly partner stats notification will not be sent at this time."
      return
    end
    @content_partners = ContentPartner.find(:all,
                          include: [ :content_partner_contacts, { user: :google_analytics_partner_summaries } ],
                          conditions: [ 'google_analytics_partner_summaries.year = :year AND 
                                            google_analytics_partner_summaries.month = :month AND content_partner_contacts.email IS NOT NULL', 
                                            { year: last_month.year, month: last_month.month } ] )
    @content_partners.each do |content_partner|
      content_partner.content_partner_contacts.each do |contact|
        Notifier.content_partner_statistics_reminder(content_partner, contact,
          Date::MONTHNAMES[last_month.month], last_month.year).deliver
      end
    end
    render text: "Monthly partner stats notification sent"
  end

end
