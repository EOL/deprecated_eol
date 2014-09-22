module ContentPartners::Resources::HarvestEventsHelper
  def event_not_published
    I18n.t(:content_partner_resource_harvest_event_not_published)
  end

  def event_currently_published
    I18n.t(:content_partner_resource_harvest_event_current_published)
  end
  
  def event_previously_published
    I18n.t(:content_partner_resource_harvest_event_previously_published)
  end
end
