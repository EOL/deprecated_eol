EOL.handle_special_anchors_in_location_hash = function() {
  if(location.hash != "") {
    var name  = location.hash.replace(/#/, '').replace(/\?.*$/, '');
    var reply = name.replace('reply-to-', '');
    if (name == reply) {
      EOL.highlight_comment($('#'+name), true);
    } else {
      $('#'+reply).find('li.reply a').click();
    }
  }
};
EOL.highlight_comment = function(el, reply) {
  if($(el).size() == 0) {
    return false;
  }
  var dest = $(el).offset().top;
  $('li').removeClass('highlight');
  el.closest('li').toggleClass('highlight');
  if (!reply) { // Don't scroll for replies; they scroll to the textarea.
    $("html,body").animate({ scrollTop: dest}, 650);
  }
  return(false);
};
EOL.reply_to = function($el) {
  var href = $el.attr('href');
  var redirected = EOL.jump_to_comment($('#'+href.replace(/^.*#reply-to-/, '')), href, true);
  if(!redirected) {
    var $form = $('form#new_comment');
    if ($form.size() == 0) { // No form on this page.
      EOL.redirect_to_comment_source(href);
    } else {
      $("html,body").animate({ scrollTop: $form.offset().top }, 650);
      EOL.add_reply_details($form, $el);
      $('a#reply-cancel').click(function( event ) {
        event.preventDefault();
        EOL.reset_reply_details($form);
      });
      $form.find('textarea').focus();
    }
  }
};
EOL.reset_reply_details = function($form) {
  var $submit = $form.find(':submit');
  $submit.val($submit.data('post'));
  $submit.parent().find('span').remove();
  EOL.set_reply_fields($form, '');
  $('li').removeClass('highlight');
};
EOL.add_reply_details = function($form, $reply_link) {
  var $submit = $form.find(':submit');
  $submit.parent().find('span').remove();
  $submit.data('post', $submit.val()).val($submit.data('reply'));
  $submit.after('<span id="reply-to">@'+$reply_link.data('reply-to')+' &nbsp; <a id="reply-cancel" href="#">'+$submit.data('cancel')+'</a></span>');
  EOL.set_reply_fields($form, $reply_link);
};
EOL.set_reply_fields = function($form, $el) {
  $form.find('input#comment_reply_to_type').val($el ? $el.data('reply-to-type') : '');
  $form.find('input#comment_reply_to_id').val($el ? $el.data('reply-to-id') : '');
};
EOL.follow_reply = function(el) {
  var href = $(el).attr('href');
  EOL.jump_to_comment($(href), href, false);
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
    EOL.highlight_comment(target, reply);
    return(false);
  }
};
// We can't use delegate() here because some pieces are missing on the initial page-load (for the worklist):
// I'm also trying to generalize this *slightly* simply because I think (but have not verified) that CSS selectors
// work faster within a smaller scope (as opposed to the entire document).
EOL.init_comment_behaviours = function() {
  var $feed = $("ul.feed");
  var $goto_source_links = $feed.find("blockquote a[href^=#]");
  $goto_source_links.unbind("click");
  $goto_source_links.click(function( event ) {
    event.preventDefault();
    EOL.follow_reply($(this));
  });
  var $reply_links = $feed.find("ul.actions li.reply a");
  $reply_links.unbind("click");
  $reply_links.click(function( event ) {
    event.preventDefault();
    EOL.reply_to($(this));
  });
  var $edit_comment_links = $feed.find("ul.actions a.edit_comment");
  $edit_comment_links.unbind("click");
  $edit_comment_links.click(function( event ) {
    event.preventDefault();
    $(this).closest("ul.actions").hide();
    $(this).closest(".details").after('<div class="comment_edit_form"></div>');
    var $update = $(this).closest(".details").next(".comment_edit_form");
    EOL.ajax_get($(this), {update: $update, type: 'GET'});
  });
  var $cancel_edit_links = $feed.find(".comment_edit_form a");
  $cancel_edit_links.unbind("click");
  $cancel_edit_links.click(function( event ) {
    event.preventDefault();
    $(this).closest(".comment_edit_form").hide().prev('.details').find("ul.actions").show().end().end().remove();
  });
  var $submit_edit_buttons = $feed.find(".comment_edit_form input[type='submit']");
  $submit_edit_buttons.unbind("click");
  $submit_edit_buttons.click(function( event ) {
    event.preventDefault();
    EOL.ajax_submit($(this));
  });
  var $delete_comment_links = $feed.find("form.delete_comment input[type='submit']");
  $delete_comment_links.unbind("click");
  $delete_comment_links.click(function( event ) {
    event.preventDefault();
    if (confirm($(this).data('confirmation'))) {
      EOL.ajax_submit($(this));
    }
  });
};

$(function() {
  EOL.init_comment_behaviours();
  EOL.handle_special_anchors_in_location_hash();
  $('ul.feed').ajaxSuccess(function() {
    EOL.init_comment_behaviours();
  });
});

