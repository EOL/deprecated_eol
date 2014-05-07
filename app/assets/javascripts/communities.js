//= require jquery.spotlite.js

if ($.fn.spotlite !== undefined) {
  $(function() {
    $.ajax({
      url: "/users/usernames",
      dataType: 'json',
      success: function(data) {
        $("dd.invite").spotlite({pool: data}).find("textarea").hide().end().find(":text").show();
        $("#community_new form :submit").on('click', function() {
          var i = 0;
          // If you click twice for some reason, we really need to remove these:
          $(this).closest('form').find('.spotlite-results input').remove();
          $(this).closest('form').find('.spotlite-results li').each(function(){
            $(this).append('<input type="hidden" value="'+$(this).html()+'" name="invite_list['+ i++ +']"/>');
          });
        });
      }
    });
  });
}

