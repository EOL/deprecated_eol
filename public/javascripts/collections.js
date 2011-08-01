// NOTE = this DUPLICATES what's in appliction.js, but I had to make modifications.  If you're getting weird
// behaviours, just remove this block from application.js (and keep this one):

EOL.init_collection_item_behaviours = function($collection) {
  var $li = $(this);
  $li.find("p.edit").show().next().hide().end().find("a").click(function() {
    $(this).parent().hide().prev().hide().next().next().show();
    return(false);
  });
  // TODO try changing the input to :submit, which is a jQuery shortcut
  $li.find(".collection_item_form input[type='submit']").click(function() {
    var $node = $(this).closest("li");
    EOL.ajax_submit($(this), {
      update: $node,
      data: "_method=put&commit_annotation=true&" +
        $(this).closest(".collection_item_form").find("input, textarea").serialize(),
      complete: function() {
        $node.find(".collection_item_form a").closest(".collection_item_form").hide().prev().show().prev().show()
      }
    });
    return(false);
  });
  $li.find(".collection_item_form a").click(function() {
    $(this).closest(".collection_item_form").hide().prev().show().prev().show();
    return(false);
  });
}

$(function() {
  $('#collections #sort_by').change(function() {$(this).closest('form').find('input[name="commit_sort"]').click();});
  $('#collections input[name="commit_sort"]').hide();
  (function($collection) { // TODO - I don't understand this syntax (see the end, too).
    $collection.find("ul.object_list li").each(EOL.init_collection_item_behaviours);
  })($("#collections"));
});
