$(function() {
  $('form#stats_form').unbind('submit');
  $('form#stats_form').submit(function() {
    var $f = $(this).closest('form');
    $('<input>').attr({
        type: 'hidden',
        name: 'ajax',
        value: 1
    }).appendTo($f);
    EOL.ajax_submit($f, { update: $('#stats_report'), type: 'GET' });
    return(false);
  });
});
