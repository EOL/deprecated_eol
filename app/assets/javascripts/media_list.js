//= require jplayer/js/jquery.jplayer.min

/*
  This is largely a collection of behaviours for the media tab of a taxon page. A lot going on.
*/

if(!EOL) { var EOL = {}; }

EOL.media_list_open_images_behaviour = function() {
  (function($media_list) {
    $media_list.find("li .overlay").click(function() {
      window.location = $(this).parent().find("a").attr("href");
      return false;
    });
  })($("#media_list"));
};

EOL.media_list_switch_entry_behaviours = function() {
  (function($switch_hierarchy_entry) {
    if ($("#switch_hierarchy_entry").length > 0) {
      $(".taxon_concept_exemplar_image").hide();
    }
  })($("#switch_hierarchy_entry"));
};

EOL.media_list_play_behaviours = function() {
  (function($media_list) {
    $media_list.find("a.play").each(function() {
      switch($(this).attr('data-mime_type')) {
        case 'audio/mpeg':
          var media = { mp3: $(this).attr('href') };
          var supplied = "mp3";
          break;
        default:
          // Mime type unknown so we remove redundant links
          $(this).parent("div").find("a.pause").remove();
          $(this).parent("div").find("a.stop").remove();
          var media = {};
      }
      $(this).parent('div').prev("div").jPlayer({
        swfPath: "/assets/jplayer/js",
        supplied: supplied,
        cssSelectorAncestor: "#" + $(this).parent('div').attr("id"),
        cssSelector: {
          play: ".play",
          pause: ".pause",
          stop: ".stop",
          currentTime: ".current_time",
          duration: ".duration"
        },
        ready: function () {
          $(this).jPlayer("setMedia", media);
        }
      }).bind($.jPlayer.event.play, function() {
        $(this).jPlayer("pauseOthers");
      });
    });
  })($("#media_list"));
};

EOL.media_list_associations_behaviours = function() {
  (function($media_list) {
    var $li = $media_list.find("li");
    $li.find(".associations").hide();
    $li.find(".flag").accessibleHover(
      function() {
        $(this).parent().find(".associations").addClass('balloon').show();
      },
      function() {
        $(this).parent().find(".associations").hide().removeClass('balloon');
    });
  })($("#media_list"));
};

EOL.media_list_filter_behaviours = function() {
// uncheck media list filter All when other options are selected
$("#media_list #sidebar input[type=checkbox][value!='all']").click(function() {
  $("#media_list #sidebar input[type=checkbox][value='all'][name='"+ $(this).attr('name') +"']").prop("checked", false);
});
// uncheck all other media list filter options when All is selected
$("#media_list #sidebar input[type=checkbox][value='all']").click(function() {
  $("#media_list #sidebar input[type=checkbox][value!='all'][name='"+ $(this).attr('name') +"']").prop("checked", false);
});
// disable the checkboxes for filter categories with no results
$("#media_list #sidebar li.no_results input[type=checkbox]").attr("disabled", true);
};

EOL.media_video_behaviour = function() {
  $('#main .media video embed').each(function() {
    var test_video = document.createElement('video');
    cant_play_video = (!test_video.canPlayType || !test_video.canPlayType('video/mp4'));
    if (cant_play_video) {
      var video = $(this).parent();
      video.parent().html(video.html());
    }
  });
};


EOL.media_prefer_behaviour = function() {
  $('td.preferred_entry_selector input[type="radio"]:not(:checked)').click(function() {
    var form = $(this).closest('form');
    form.submit();
  });
};

EOL.media_exemplar_behaviour = function() {
  console.log('EOL.media_exemplar_behaviour');
  $('#media_list form.taxon_concept_exemplar_image').each(function() {
    $(this).find(":submit").hide().end().find('label, input[type="radio"]').accessibleClick(function() {
      $(this).addClass('busy').parent().find('input[type="radio"]').attr('checked', true).closest('form').submit();
    });
  });
}

EOL.feed_behaviour = function() {
  (function($feed){
    $feed.children().each(function() {
      var $li = $(this);
      $li.delegate("ul.actions a.edit_comment", "click keydown", function( event ) {
        event.preventDefault();
        $(this).closest("ul.actions").hide();
        $(this).closest(".details").after('<div class="comment_edit_form"></div>');
        var $update = $(this).closest(".details").next(".comment_edit_form");
        EOL.ajax_get($(this), {update: $update, type: 'GET'});
      });
      $li.delegate(".comment_edit_form a", "click keydown", function( event ) {
        event.preventDefault();
        $(this).closest(".comment_edit_form").hide().prev('.details').find("ul.actions").show().end().end().remove();
      });
      $li.delegate(".comment_edit_form input[type='submit']", "click keydown", function( event ) {
        event.preventDefault();
        EOL.ajax_submit($(this));
      });
      $li.delegate("form.delete_comment input[type='submit']", "click keydown", function( event ) {
        event.preventDefault();
        if (confirm($(this).data('confirmation'))) {
          EOL.ajax_submit($(this));
        }
      });
    });
  })($("ul.feed"));
};

EOL.enableRatings = function() {
  // Wouldn't it be nice if ratings were Ajaxified?
  $('.media .ratings .rating ul > li > a').unbind('click').click(function() {
    var $update = $(this).closest('div.ratings');
    EOL.ajax_submit($(this), {url: $(this).attr('href'), update: $update, type: 'GET'});
    return(false);
  });
};

