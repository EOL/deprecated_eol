//= require 'worklist_curation'
//= require 'permalink'
//= require 'jplayer/js/jquery.jplayer.min'

if(!EOL) { var EOL = {}; }

EOL.init_worklist_behaviors = function() {
  init_comments();
  init_curation();
  $("#tasks li").unbind('click');
  $('#tasks li').on('click', function() {
    if($('#tasks li.active span.indicator').html() !== '') {
      $('#tasks li.active span.indicator').removeClass('invisible');
    }

    $(this).closest('ul').find("li").removeClass("active");
    $(this).find('span.indicator').addClass('invisible');
    $(this).addClass("active");
    var $update = $(this).closest('#worklist').find('#task');
    EOL.ajax_get($(this).find("a"), {update: $update, type: 'GET', complete: function() { EOL.init_worklist_behaviors(); } });
    return(false);
  });

  $('#worklist .filters form input[type=submit]').unbind('click');
  $('#worklist .filters form input[type=submit]').on('click', function() {
    var $f = $(this).closest('form');
    $('<input>').attr({
        type: 'hidden',
        name: 'ajax',
        value: 1
    }).appendTo($f);
    EOL.ajax_submit($f, {update: $(this).closest('#worklist'), type: 'GET', complete: function() { EOL.init_worklist_behaviors(); } });
    return(false);
  });

  $('#tasks p.more a').unbind('click');
  $('#tasks p.more a').on('click', function() {
    var $update = $(this).closest('#worklist');
    var current_link = $(this).attr('href');
    $(this).attr('href', current_link + (current_link.indexOf('?') != -1 ? "&ajax=1" : "?ajax=1"));
    EOL.ajax_get($(this), {update: $update, type: 'GET', complete: function() { EOL.init_worklist_behaviors(); } });
    return(false);
  });

  $('#worklist #task .ratings .rating a').unbind('click');
  $('#worklist #task .ratings .rating a').on('click', function() {
    var $update = $(this).closest('div.ratings');
    EOL.ajax_submit($(this), {url: $(this).attr('href'), update: $update, type: 'GET', complete: function() { EOL.init_worklist_behaviors(); } });
    return(false);
  });

  $('#worklist #task form.comment input[type=submit]').unbind('click');
  $('#worklist #task form.comment input[type=submit]').on('click', function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), { update: $(this).closest('#task'), complete: function() { EOL.init_worklist_behaviors(); update_active_indicator('Commented'); } } );
    return(false);
  });

  $('#worklist #task form.review_status input[type=submit]').unbind('click');
  $('#worklist #task form.review_status input[type=submit]').on('click', function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task'), complete: function() { EOL.init_worklist_behaviors(); update_active_indicator('Saved'); } } );
    return(false);
  });

  $('#worklist #task form.ignore_data_object input[type=submit]').unbind('click');
  $('#worklist #task form.ignore_data_object input[type=submit]').on('click', function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task'), complete: function() { EOL.init_worklist_behaviors(); update_active_indicator('Ignored'); } } );
    return(false);
  });
  

};

$(window).load(function() {
  resize_task_panel();
  EOL.init_worklist_behaviors();
});

function resize_task_panel() {
  $('#task').css('min-height', $('#tasks ul').css('height'));
}
function update_active_indicator(message) {
  if(message == 'Saved') {
    $('#tasks li.active').removeClass('ignored');
    $('#tasks li.active').addClass('saved');
    $('#tasks li.active span.indicator').html(message);
  }else if(message == 'Ignored') {
    $('#tasks li.active').removeClass('saved');
    if($('#tasks li.active').hasClass('ignored')) {
      $('#tasks li.active').removeClass('ignored');
      $('#tasks li.active span.indicator').html('');
    }else
    {
      $('#tasks li.active').addClass('ignored');
      $('#tasks li.active span.indicator').html(message);
    }
  }else
  {
    $('#tasks li.active span.indicator').html(message);
  }
  init_comments();
}
function init_comments() {
  if (EOL.init_comment_behaviours !== undefined) {
    // This ends up getting called twice on page-load, but we really do need it here for when a new task is loaded.
    EOL.init_comment_behaviours();
    // Added on 4.30.12 to fix #WEB-3551
    $('ul.feed').ajaxSuccess(function() {
      EOL.init_comment_behaviours();
    });
  }
}
function init_curation() {
  if (EOL.init_curation_behaviours !== undefined) {
    // This ends up getting called twice on page-load, but we really do need it here for when a new task is loaded.
    EOL.init_curation_behaviours();
  }
}
