module ResourcesHelper

  def frequency(hours)
    case hours
    when 0
      I18n.t("resource_import_frequency.once")
    when 7 * 24
      I18n.t("resource_import_frequency.weekly")
    when 30 * 24
      I18n.t("resource_import_frequency.monthly")
    when 60 * 24
      I18n.t("resource_import_frequency.bimonthly")
    when 91 * 24
      I18n.t("resource_import_frequency.quarterly")
    else
      hours.nil? ? '' : I18n.t("resource_import_frequency.hours_with_count", count: hours)
    end
  end
end
