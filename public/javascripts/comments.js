EOL.highlight_comment = function(el) {
  if($(el).size() == 0) {
    return false;
  }
  var dest = $(el).offset().top;
  $('li').removeClass('highlight');
  el.closest('li').toggleClass('highlight');
  $("html,body").animate({ scrollTop: dest}, 650);
  return(false);
};

EOL.reply_to = function(el) {
  var $el = $(el.target);
  var $href = $el.attr('href');
  var $target = $('a[name='+$href.replace(/^.*#reply-to-/, '')+']');
  var redirected = EOL.jump_to_comment($target, $href, true);
  if(redirected) {
    return(false);
  }
  var replying_to = $el.data('reply-to');
  $('span.reply').show(); // Show any that may be hidden...
  $('form#reply').remove(); // ...but remove the forms.
  var $form = $('form#new_comment').clone().attr("id","reply");
  if ($form.size() == 0) { // No form on this page.
    EOL.redirect_to_comment_source($href);
    return(false);
  }
  $el.parent().hide().parent().parent().after($form);
  var $submit = $form.find(':submit');
  $submit.data('post', $submit.val()).val($submit.data('reply'));
  $submit.after('<a id="reply-cancel" href="#">'+$submit.data('cancel')+'</a>');
  $('a#reply-cancel').click(function() {$('form#reply').remove(); $('span.reply').show(); return(false); });
  $form.find('p.reply-to').remove();
  var $tarea = $form.find('textarea');
  $form.find('input#comment_reply_to_type').val($el.data('reply-to-type'));
  $form.find('input#comment_reply_to_id').val($el.data('reply-to-id'));
  $tarea.focus();
  return(false);
};

EOL.follow_reply = function(el) {
  var $href = $(el).attr('href');
  var $target = $('a[name='+$href.replace(/^.*#/, '')+']');
  EOL.jump_to_comment($target, $href, false);
};

EOL.redirect_to_comment_source = function(href, reply) {
  window.location = '/activity_logs/find/'+href.replace(/^.*-(\d+)$/, '\$1')+'?'+
    $.param({type: href.replace(/^.*[#-]([^-]+)-\d+$/, '\$1'), reply: reply});
};

EOL.jump_to_comment = function(target, href, reply) {
  if (target.size() == 0) {
    EOL.redirect_to_comment_source(href, reply);
    return(true);
  } else {
    EOL.highlight_comment(target);
    return(false);
  }
};

EOL.init_comment_behaviours = function(items) {

  items.each(function() {
    var $li = $(this);
    $li.find('p span.reply a').click(EOL.reply_to);
    // TEMP - we want to try this without show/hide: $(this).find('span').show();
    // $li.find('p span').hide().parent().parent().mouseover(function() {
      // $(this).find('span').show();
    // }).mouseleave(function() {
      // $(this).find('span').hide();
    // });

    $li.find('blockquote p a[href^=#]').click(function() { EOL.follow_reply($(this)); });

  });
}

$(function() {
  EOL.init_comment_behaviours($('ul.feed li'));
  if(location.hash != "") {
    var name  = location.hash.replace(/#/, '').replace(/\?.*$/, '');
    var reply = name.replace('reply-to-', '');
    if (name == reply) {
      EOL.highlight_comment($('a[name='+name+']'));
    } else {
      $('a[name='+reply+']').parent().find('span.reply a').click();
    }
  }
});
