module ContentPartners::ResourcesHelper

    def attribute_or_empty(attribute)
      attribute.blank? ? I18n.t(:value_empty) : attribute
    end

    def time_or_empty(time)
      format_date_time(time, format: :medium) || I18n.t(:value_empty)
    end

    def link_to_url_or_empty(url)
      if url.blank?
        I18n.t(:value_empty)
      else
        link_to url.sub(/^.*\//, ''), url
      end
    end

    def request_to_publish_hierarchy_button(hierarchy)
      button_to(
        I18n.t("helpers.submit.hierarchy.request_publish"),
        request_publish_content_partner_resource_hierarchy_path(
          @partner, @resource, hierarchy
        ),
        data: { confirm:
          I18n.t(:content_partner_resource_hierarchy_confirm_request_publish,
                 hierarchy_label: h(hierarchy.label)) }
      )
    end

    def en_resource_status
      status = @resource.resource_status.try(:label, "en")
      if status
        status.downcase.gsub(" ","_")
      else
        "unknown"
      end
    end
end
