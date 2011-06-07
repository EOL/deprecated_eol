$(function() {
  $("#taxonomy_detail form.comment").each(function() {
    var $form = $(this).hide(),
        $a = $("<a />", {
          href: "#",
          text: "leave a comment",
          "class": "button",
          click: function() {
            $(this).closest("p").hide().closest(".article").find("form.comment").show();
            return false;
          }
        });
    $a.appendTo($("<p />").insertBefore($form));
    $("<a />", {
      href: "#",
      text: "cancel",
      click: function() {
        $(this).closest("form").hide().prev("p").show();
        return false;
      }
    }).appendTo($form.find(".actions"));
  });
});
