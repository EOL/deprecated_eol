if ($.fn.spotlite != undefined) {
  $(function() {
    $.ajax({
      url: "/users/usernames.js",
      dataType: 'json',
      success: function(data) {
        $("#community_new dd.invite").spotlite({pool: data}).find("textarea").hide().end().find(":text").show();
        $("form#new_community :submit").click(function() {
          var i = 0
          // If you click twice for some reason, we really need to remove these:
          $(this).closest('form').find('.spotlite-results input').remove();
          $(this).closest('form').find('.spotlite-results li').each(function(){
            $(this).append('<input type="hidden" value="'+$(this).html()+'" name="invite_list['+ i++ +']"/>')
          });
        });
      }
    });
  });
}

