$(function() {
  (function($ss) {
    $ss.find(".images").cycle({
      speed: 500,
      timeout: 0,
      pagerAnchorBuilder: function(idx) {
        return $ss.selector + " .thumbnails a:eq(" + idx + ")";
      }
    });
    $ss.find(".thumbnails a").click(function() {
      var $e = $(this).closest("li");
      $e.closest("ul").find(".active").removeClass("active");
      $e.addClass("active");
      return false;
    });
  })($(".gallery"));

  $("input[placeholder]").each(function() {
    var $e = $(this),
        placeholder = $e.attr("placeholder");
    $e.removeAttr("placeholder").val(placeholder);
    $e.bind("focus blur", function(e) {
      if (e.type === "focus" && $e.val() === placeholder) { $e.val(""); }
      else { if (!$e.val()) { $e.val(placeholder); } }
    });
  });
});
