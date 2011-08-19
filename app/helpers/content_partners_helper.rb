module ContentPartnersHelper

  def display_content_partners_navigation?
    @partner && @partner.id && ((action_name == 'show' && (controller_name != 'resources' && controller_name != 'content_partner_agreements')) || action_name == 'index')
  end

end