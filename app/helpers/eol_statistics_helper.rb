module EolStatisticsHelper

  # Compares statistics for dates one and two and returns class names for both
  def greater(is_greatest = false)
    is_greatest ? 'greater' : nil
  end

  # Init options as JSON to pass to jQuery datepicker
  def jquery_ui_datepicker_opts
    { :closeText => I18n.t('datepicker.close'),
      :currentText => I18n.t('datepicker.current'),
      :nextText => I18n.t('datepicker.next'),
      :prevText => I18n.t('datepicker.previous'),
      :monthNames => I18n.t('datepicker.month_names'),
      :monthNamesShort => I18n.t('datepicker.month_names_short'),
      :dayNames => I18n.t('datepicker.day_names'),
      :dayNamesShort => I18n.t('datepicker.day_names_short'),
      :dayNamesMin => I18n.t('datepicker.day_names_min'),
    }.to_json
  end

end
