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

  $("table.ontology :checkbox").live("click", function() {
    var tr = $(this).closest('tr');
    if(tr.hasClass('header')) return;
    set_ignored_or_selected(this.checked, tr);
  });

  $("table.ontology tr:not(.header):not(.existing)").live("click", function(e) {
    if(e.target.type !== 'checkbox') {
      var checkbox = $(this).find('td.checkbox :checkbox');
      checkbox.prop('checked', !checkbox.prop('checked'));
      set_ignored_or_selected(checkbox.prop('checked'), $(this));
    }
  });

  $("table.ontology #select_all").live("click", function() {
    $(this).closest('form').find(':checkbox').prop('checked', this.checked);
    set_ignored_or_selected(this.checked, $(this).closest('form').find('tr:not(.header):not(.existing)'));
  });
});

function set_ignored_or_selected(checked, tr) {
  if(checked) {
    tr.addClass('selected');
    tr.removeClass('ignored');
  } else {
    tr.addClass('ignored');
    tr.removeClass('selected');
  }
}