# encoding: utf-8

class ContentPartner
  # Encapsulates the variables needed to render the show/edit pages.
  class Meta
    def title
      I18n.t(:content_partners_page_title)
    end

    def subtitle
      I18n.t(:content_partner_new_page_subheader)
    end
  end
end
