$(function(){

  $('a.button.link').on('click', function(e) {
    $('.permalink').css({ display: 'none' }).hide();
    var permalink = $(this).closest('ul').siblings('.permalink');
    permalink.css({ display: 'block' }).show();
    return false;
  });

  $('.permalink .close').on('click', function(e) {
    var permalink = $(this).closest('.permalink');
    permalink.css({ display: 'none' }).hide();
    return false;
  });

  $(".permalink input[type=text]").on('click', function() {
     $(this).select();
  });

  // if the post getting linked to is on the page, jump to it
  $('a:not(.close a):not(.button.link)').on('click', function(e) {
    var url = $(this).attr('href');
    return move_to_post_if_available(url, true);
  });

  // if this is a post, jump to the post
  move_to_post_if_available(window.location.pathname, false);
});

function move_to_post_if_available(url, modify_history) {
  if(m = url.match(/\/posts\/([0-9]+)$/)) {
    var post_id = m[1];
    if($("#post_" + post_id).length > 0) {
      if(modify_history) {
        history.pushState(null, null, url);
      }
      move_to_post(post_id);
      return false;
    }
  }
}

function move_to_post(post_id) {
  $('html,body').animate({ scrollTop: $("#post_" + post_id).offset().top }, 300);
}

// forum uses some custom Ckeditor CSS
if(typeof CKEDITOR != "undefined")
{
  CKEDITOR.config.contentsCss = '/assets/forum.css';
  CKEDITOR.config.bodyClass = 'post_text';
}
