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
  var $form = $('form#new_comment');
  if ($form.size() == 0) { // No form on this page.
    EOL.redirect_to_comment_source($href);
    return(false);
  }
  $("html,body").animate({ scrollTop: $form.offset().top }, 650);
  var $submit = $form.find(':submit');
  $submit.data('post', $submit.val()).val($submit.data('reply'));
  $submit.after('<a id="reply-cancel" href="#">'+$submit.data('cancel')+'</a>');
  $submit.after('<span id="reply-to">@'+$el.data('reply-to')+' &nbsp; </span>');
  $('a#reply-cancel').click(function() {
    $(this).prev().remove();
    $(this).remove();
    $submit.val($submit.data('post'));
    $form.find('input#comment_reply_to_type').val('');
    $form.find('input#comment_reply_to_id').val('');
    $('li').removeClass('highlight');
    return(false);
  });
  $form.find('input#comment_reply_to_type').val($el.data('reply-to-type'));
  $form.find('input#comment_reply_to_id').val($el.data('reply-to-id'));
  var $tarea = $form.find('textarea');
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

    $li.find('blockquote p a[href^=#]').click(function() { EOL.follow_reply($(this)); });

    // TODO try changing the input to :submit, which is a jQuery shortcut
    $li.find(".edit_comment_form input[type='submit']").click(function() {
      var $node = $(this).closest("li");
      EOL.ajax_submit($(this), {
        update: $node,
        data: $(this).closest(".edit_comment_form").find("input, textarea").serialize(),
        complete: function() {
          $node.addClass('highlight');
          setTimeout(function(){
            $node.removeClass('highlight');
          }, 2000);
          EOL.init_comment_behaviours($node);
        }
      });
      return(false);
    });

    $li.find('.edit_comment_form a').click(function() {
      $(this).closest('.edit_comment_form').hide().prev().show().prev().show();
      return(false);
    });

    $li.find('span.edit a').click(function() {
      $('form#reply').remove();
      $('span.reply').show();
      var comment_body = $(this).attr('data-to-edit');
      $(this).closest('.details').prev().hide().next().hide().next().show().find('textarea').val(comment_body);
      return(false);
    });

    $li.find('span.delete a').click(function() {
      var comment_id = $(this).attr('data-to-delete');
      var $node = $(this).closest("li");
      EOL.ajax_submit($(this), {
        update: $node,
        data: "_method=delete",
        url: "/comments/" + comment_id,
        complete: function() {
          $node.addClass('highlight');
          setTimeout(function(){
            $node.removeClass('highlight');
          }, 2000);
          EOL.init_comment_behaviours($node);
        }
      });
      return(false);

    });
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
