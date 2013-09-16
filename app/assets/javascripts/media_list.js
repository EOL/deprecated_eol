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

EOL.replace_dato_id = function(id) {
  $('#right-image-buttons a.popup-link, #rating-'+id+' a, #large-image-attribution-button-popup-link').each(function() {
    new_href = $(this).attr('href').replace(/data_objects\/\d+/, 'data_objects/'+id);
    $(this).attr('href', new_href);
  });
};

EOL.click_selected_image = function() {
  // If there is no slected image, just click the first one:
  if(!typeof selected_image_id === "undefined") {
    if(!selected_image_id) {
      $("#thumbnails a:nth-child(1)").click();
    } else {
      $("#thumbnails a#thumb-"+selected_image_id).click();
    }
  }
};

EOL.toggle_main_img_icons = function(id) {
  $('#large-image-button-group li.status_icon').hide();
  // This is a little confusing, sorry.  Basically, we look at the thumbnail for the image we're showing.
  // For every icon that is VISIBLE on the thumbnail, we make that same icon visible on the large image.
  $('ul[data-data_object_id='+id+'] li:visible').each(function() {
    var classes = $(this).attr('class').split(' ');
    /// ...we look at the class name(s) of that visible icon...
    for (var i in classes) {
      if (classes[i] == 'status_icon') { continue; } // ...(and skip this class)...
      // ...and finally show the icon under the main image with the same class name (they are created with the same partial):
      // Note: weird, but true--show() doesn't work... it forces a display that breaks the icon down a line.  This works:
      $('#large-image-button-group li.'+classes[i]).css({display:'inline-block'});
    }
  });
};

EOL.init_image_collection_behaviors = function() {
  // Image pagination:
  $('.mc-navigation a').click(function() {
    $.ajax({
      url: $(this).attr('href'),
      beforeSend: function() {EOL.close_open_overlays(); $('#media-images').fadeTo(300, 0.3);},
      success: function(response) {$('#media-images').html(response);},
      error: function() {$('#media-images').html('<p>Sorry, there was an error.</p>');},
      complete: function() {
        // Removing the filter after fading in; IE7 does not anti-alias fonts that are filtered.
        $('.tooltip').hide(); // hides the 'images in yellow...' tooltip
        $('#media-images').delay(25).fadeTo(100, 1, function() {$('#media-images').css({filter:''});});
        try { EOL.Rating.init_links('#image-ratings'); } catch(e) {} // This isn't availble (or needed) for non-curators
        EOL.init_popup_overlays(); // This *needs* to be available.
        EOL.click_selected_image(); // TODO - is this duplicated?
      }
    });
    return false;
  });
  // clicking the large image shows its attribution
  $('img.main-image').click(function() {
    $('#large-image-attribution-button-popup-link').click(); // "click" the PopupLink
  });
  // Clicking on a thumbnail does... a lot:
  $("#thumbnails a").click(function() {
    EOL.close_open_overlays();
    var id = $(this).attr('href').replace(/^.*\/(\d+)/, '$1');
    $('.overlay').fadeOut(200);
    $("#notes-container div.mc-notes, #large-image .main-image-bg, #image-ratings .image-rating").hide();
    $("#notes-container #mc-notes-"+id+", #large-image #image-"+id+", #image-ratings, #image-ratings #rating-"+id).show();
    $("#large-image-comment-button .comment_button").hide();
    $("#large-image-comment-button #comment_button_id_"+id).show();
  $("#large-image-comment-button").removeClass("hide");
    EOL.replace_dato_id(id);
    EOL.toggle_main_img_icons(id);
    EOL.init_popup_overlays();
    EOL.toggle_photosynth_icon(id);
    return false;
  });
  EOL.click_selected_image();
};

EOL.toggle_photosynth_icon = function(id) {
  var source_url = $("#mc-notes-"+id+" a.source_url").attr('href');
  if(source_url == undefined || source_url.search(/photosynth.net/) == -1) { //regular static image    
    $("#photosynth-message").html("");
    $("#photosynth-message").unbind('click');
  } else { //photosynth image
    $("#photosynth-message").html("<img src='http://mslabs-999.vo.llnwd.net/e1/inc/images/master/logo.png' height='27' alt='Photosynth' title='Image is part of a Photosynth'/>");
    $("#photosynth-message").click(function() {
      $("#large-image #image-"+id+" td").html("<iframe frameborder='0' src='" + source_url.replace("view.aspx", "embed.aspx") + "&delayLoad=true&slideShowPlaying=false' width='425' height='355'></iframe>");
    });
  }
};
