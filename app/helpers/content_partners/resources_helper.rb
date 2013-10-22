module ContentPartners::ResourcesHelper

    def attribute_or_empty(attribute)
      attribute.blank? ? I18n.t(:value_empty) : attribute
    end

    # TODO - we MUST need a helper somewhere for all the licenses we display.  :|
    def license_title_or_empty(license)
      license.blank? ? I18n.t(:value_empty) : I18n.t("license_#{license.title.gsub(/[- .]/, '_').strip}")
    end

    def time_or_empty(time)
      format_date_time(time, :format => :medium) || I18n.t(:value_empty)
    end

    def link_to_url_or_empty(url)
      if url.blank?
        I18n.t(:value_empty)
      else
        link_to url.sub(/^.*\//, ''), url
      end
    end

end
