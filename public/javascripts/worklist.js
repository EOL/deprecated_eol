$(function() {
  
  $("#tasks li").unbind('click');
  $('#worklist #tasks li').click(function() {
    $(this).closest('ul').find("li").removeClass("active");
    $(this).addClass("active");
    var $update = $(this).closest('#worklist').find('#task');
    EOL.ajax_get($(this).find("a"), {update: $update, type: 'GET'});
    return(false);
  });
  
  $('#worklist #task .ratings .rating a').unbind('click');
  $('#worklist #task .ratings .rating a').click(function() {
    var $update = $(this).closest('#worklist').find('#task');
    EOL.ajax_get($(this), {update: $update, type: 'GET', complete: update_active_indicator('Rated')});
    return(false);
  });
  
  $('#worklist #task form.comment input[type=submit]').unbind('click');
  $('#worklist #task form.comment input[type=submit]').click(function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task'), complete: update_active_indicator('Commented')});
    return(false);
  });
  
  $('#worklist #task form.review_status input[type=submit]').unbind('click');
  $('#worklist #task form.review_status input[type=submit]').click(function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task'), complete: update_active_indicator('Saved')});
    return(false);
  });
  
  $('#worklist #task form.ignore_data_object input[type=submit]').unbind('click');
  $('#worklist #task form.ignore_data_object input[type=submit]').click(function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task'), complete: update_active_indicator('Ignored')});
    return(false);
  });
  
  
});

function update_active_indicator(message) {
  $('#worklist #tasks li.active span.indicator').html(message);
  $('#worklist #tasks li.active span.indicator').removeClass('invisible');
}

