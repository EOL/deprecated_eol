# Helpers for content patnter views
module ContentPartnersHelper
  def display_content_partners_navigation?
    @partner && @partner.id &&
    (
      (action_name == "show" &&
       controller_name != "content_partner_agreements") ||
      (action_name == "index" && controller_name != "harvest_events")
    )
  end

  def oldest_published_harvest_time(partner)
    I18n.t(:content_partner_latest_published_harvest_event_time_ago,
           time_passed:
           time_ago_in_words(partner.latest_published_harvest_events.
                             first.published_at))
  end

  def latest_published_harvest_time(partner)
    I18n.t(:content_partner_latest_published_harvest_event_time_ago,
           time_passed:
           time_ago_in_words(partner.latest_published_harvest_events.
                             first.published_at))
  end

  def field_name(attribute)
    I18n.t "activerecord.attributes.content_partner_agreement.#{attribute}"
  end

  def field_value(val)
    val.blank? ? I18n.t(:value_empty) : val
  end

  def agreement
    if @partner.agreement.mou_url.blank?
      content_partner_agreement_path(@partner, @partner.agreement)
    else
      @partner.agreement.mou_url
    end 
  end

end
