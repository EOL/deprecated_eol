$(function() {
  $("#taxonomy_detail form.comment").each(function() {
    var $form = $(this).hide();
    $form.prev(".actions").find("a.comment").css("display", "inline-block").click(function() {
      $(this).hide().closest(".article").find("form.comment").show();
      return false;
    });
    $form.find("a.cancel").show().click(function() {
      $(this).closest("form").hide().prev(".actions").find("a.comment").show();
      return false;
    });
  });

  $("#tasks li").click(function() {
    window.location.href = $(this).find("a").attr("href");
  });
});
