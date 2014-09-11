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

  def signed_by_title
    I18n.t "activerecord.attributes.content_partner_agreement.signed_by"
  end

  def signed_by_value
    val = @partner.agreement.signed_by
    I18n.t(:value_empty) if signed_by.blank?
  end

  def signed_on_date_title
    I18n.t("activerecord.attributes.content_partner_agreement.signed_on_date")
  end
  
  def signed_on_date_value
    val = @partner.agreement.signed_on_date
    I18n.t(:value_empty) if val.blank?
  end

  def created_at_title
    I18n.t("activerecord.attributes.content_partner_agreement.created_at")
  end

  def created_at_value
    val = @partner.agreement.created_at
    I18n.t(:value_empty) if val.blank? 
  end
end
