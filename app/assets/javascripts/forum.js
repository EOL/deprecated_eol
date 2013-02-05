$(function(){
  // if the post getting linked to is on the page, jump to it
  $('a').click(function(e) {
    if(m = $(this).attr('href').match(/\/posts\/([0-9]+)$/)) {
      var post_id = m[1];
      if($("#post_" + post_id).length > 0) {
        $('html,body').animate({ scrollTop: $("#post_" + post_id).offset().top }, 300);
        return false;
      }
    }
  });
});

// forum uses some custom Ckeditor CSS
CKEDITOR.config.contentsCss = '/assets/forum.css';
CKEDITOR.config.bodyClass = 'post_text';
