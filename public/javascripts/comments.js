EOL.highlight_comment = function(el) {
  var dest = $(el).offset().top;
  $('li').removeClass('highlight');
  el.closest('li').toggleClass('highlight');
  $("html,body").animate({ scrollTop: dest}, 650);
  return(false);
};

EOL.reply_to = function(el) {
  string = $(el.target).data('reply-to');
  var $submit = $('#new_comment :submit');
  $submit.data('post', $submit.val()).val($submit.data('reply'));
  $('#new_comment p.reply-to').remove();
  $submit.before('<p class="reply-to">'+$submit.data('replying-to-x').replace('X', string)+'</p>');
  var $tarea = $('#new_comment textarea');
  $tarea.val('@'+string+': '+$tarea.val().replace(/^@[^:]+: */, ''));
  $('#new_comment input#comment_reply_to_type').val($(el.target).data('reply-to-type'));
  $('#new_comment input#comment_reply_to_id').val($(el.target).data('reply-to-id'));
  $("html,body").animate({ scrollTop: $tarea.offset().top}, 650);
  $tarea.focus();
  return(false);
};

EOL.init_comment_behaviours = function($items) {
  $items.each(function() {
    var $li = $(this);


    $li.find('p span.reply a').click(EOL.reply_to);
    $li.find('p span').hide().parent().parent().mouseover(function() {
      $(this).find('span').show();
    }).mouseleave(function() {
      $(this).find('span').hide();
    });

    $li.find('blockquote p a[href^=#]').click(function() {
      var href = $(this).attr('href');
      var target = $('a[name='+href.replace('#', '')+']');
      if (target.size() == 0) {
        window.location = '/activity_logs/find/'+href.replace(/[^0-9]/g, '')+'?type='+href.replace(/^#(.*)-.*$/, '\$1');
      } else {
        EOL.highlight_comment(target);
      }
    });

    if(location.hash != "") {
      EOL.highlight_comment($('a[name='+location.hash.replace(/#/, '').replace(/\?.*$/, '')+']'));
    }


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
});