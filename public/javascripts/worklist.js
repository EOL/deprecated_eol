$(function() {
  (function($tasks) {
    $tasks.find("ul li").click(function() {
      var $li = $(this);
      $tasks.find("ul li").removeClass("active");
      $li.addClass("active")
    });
  })($("#tasks"));
});