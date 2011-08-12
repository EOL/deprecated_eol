$(function() {
  (function($tasks) {
    $tasks.find("ul li").click(function() {
      var $li = $(this);
      $tasks.find("ul li").removeClass("active");
      $li.addClass("active");
    });
  })($("#tasks"));
  
  $("#tasks li").unbind('click');
  $('#worklist #tasks li').click(function() {
    $(this).closest('ul').find("li").removeClass("active");
    $(this).addClass("active");
    var $update = $(this).closest('#worklist').find('#task');
    EOL.ajax_get($(this).find("a"), {update: $update, type: 'GET'});
    return(false);
  });
  
  $('#worklist #task .ratings .rating a').click(function() {
    var $update = $(this).closest('#worklist').find('#task');
    EOL.ajax_get($(this), {update: $update, type: 'GET'});
    return(false);
  });
  
  
  $('#worklist #task form.comment input[type=submit]').click(function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task')});
    return(false);
  });
  
  $('#worklist #task form.review_status input[type=submit]').click(function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task')});
    return(false);
  });
  
  $('#worklist #task form.ignore_data_object input[type=submit]').click(function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task')});
    return(false);
  });
  
  
});