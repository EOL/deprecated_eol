// NOTE = this DUPLICATES what's in appliction.js, but I had to make modifications.  If you're getting weird
// behaviours, just remove this block from application.js (and keep this one):
$(function() {
  $('#sort_by').change(function() {$(this).closest('form').submit();});
  (function($collection) { // TODO - I don't understand this syntax (see the end, too).
    $collection.find("ul.object_list li").each(function() {
      var $li = $(this);
      $li.find("p.edit").show().next().hide().end().find("a").click(function() {
        $(this).parent().hide().prev().hide().next().next().show();
        return(false);
      });
      $li.find(".collection_item_form input[type='submit']").click(function() {
        EOL.ajax_submit($(this), { update: $(this).closest("li") });
        return(false);
      });
      $li.find(".collection_item_form a").click(function() {
        $(this).closest(".collection_item_form").hide().prev().show().prev().show();
        return(false);
      });
    });
  })($("#collections"));
});
