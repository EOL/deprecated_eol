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
  
});