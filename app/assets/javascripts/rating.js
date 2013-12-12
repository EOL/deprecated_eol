$(function() {
  $(".rating ul a").on('click', function() {
    var $e = $(this),
        idx = $e.closest("ul").find("a").index($e);
    idx++;
    $e.closest("ul").find("li[class^=current]").removeClass()
      .addClass("current_rating_" + idx).text("Current rating: " + idx + " of 5");
    $e.closest(".ratings").addClass("rated");
    return false;
  });
});
