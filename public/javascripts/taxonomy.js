$(function() {
  $("#taxonomy_detail form.comment").each(function() {
    var $form = $(this).hide();
    $form.prev("p").find("a.comment").show().click(function() {
      $(this).hide().closest(".article").find("form.comment").show();
      return false;
    });
    $form.find("a.cancel").show().click(function() {
      $(this).closest("form").hide().prev("p").find("a.comment").show();
      return false;
    });
  });

  $("#tasks li").click(function() {
    window.location.href = $(this).find("a").attr("href");
  });
});
