$(function() {
  // EOL Statistics initialise date picker
  (function($statistics) {
    var $date_form = $statistics.find('form');

    var $datepicker_opts = $.extend(
      $date_form.data('datepicker_opts'),
      { isRTL: ($('body').css('direction') == 'rtl') ? true : false,
        showOn: "button",
        buttonImage: "/assets/v2/icon_calendar.png",
        buttonImageOnly: true,
        minDate: new Date(2012, 2 - 1, 17),
        maxDate: new Date() }
    );

    $date_form.addClass('with_picker');
    $date_form.find('label').each(function() {
      var $label = $(this);
      $label.append('<input type="hidden"/>');
      $label.find('input[type="hidden"]').datepicker($.extend($datepicker_opts, {
        defaultDate: new Date($label.find('select:eq(2)').val(),
                              $label.find('select:eq(1)').val() - 1,
                              $label.find('select:eq(0)').val()),
        onSelect: function(dateText, inst) {
          $label.find('option:selected').removeAttr('selected');
          $label.find('select:eq(0) option[value="' + inst.selectedDay + '"]').attr('selected', 'selected');
          $label.find('select:eq(1) option[value="' + (inst.selectedMonth + 1) + '"]').attr('selected', 'selected');
          $label.find('select:eq(2) option[value="' + inst.selectedYear + '"]').attr('selected', 'selected');
          $label.closest('form').submit();
        }
      }));
    });
  })($("#statistics"));
});
