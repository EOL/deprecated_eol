module ContentPartnersHelper

  def display_content_partners_navigation?
    @partner && @partner.id && ((action_name == 'show' && controller_name != 'resources') || action_name == 'index')
  end

end