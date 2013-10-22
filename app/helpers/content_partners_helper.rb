module ContentPartnersHelper

  def display_content_partners_navigation?
    @partner && @partner.id &&
    ( (action_name == 'show' && controller_name != 'content_partner_agreements') ||
      (action_name == 'index' && controller_name != 'harvest_events') )
  end

end
