if(!EOL) { var EOL = {}; }
// Fix for Chrome, adding taxa to collections on map tab (and possibly other problems). See http://stackoverflow.com/questions/7825448/webkit-issues-with-event-layerx-and-event-layery
(function(){
    // remove layerX and layerY
    var all = $.event.props,
        len = all.length,
        res = [];
    while (len--) {
      var el = all[len];
      if (el != 'layerX' && el != 'layerY') res.push(el);
    }
    $.event.props = res;
}());

// TODO - not all of these are required, if we know we won't use them:
$.ajaxSetup({accepts: {
  '*': "text/javascript, */*",
  html: "text/javascript",
  json: "application/json, text/javascript",
  script: "text/javascript",
  text: "text/plain",
  xml: "application/xml, text/xml"
}});

// Globally change cursor to busy when we're waiting on AJAX event to finish,
// except for the homepage march of life
$("html :not(.thumbnails ul li)").bind("ajaxStart", function(){
  $(this).addClass('busy');
}).bind("ajaxStop", function(){
  $(this).removeClass('busy');
});
    
$(document).on('mouseover', '#social_sharing .facebook', function() {
  if($('.jcrop-holder').length > 0) {
    $('#social_sharing .facebook').css('z-index', parseInt($('.jcrop-holder > div:first').css('z-index')) + 1);
  }
});

EOL.check_siblings = function(of, val) {
  try { $($(of).siblings()).prop('checked', val); }
  catch(err) { /* Don't care if this fails. */ }
};

EOL.restorable_tabs_behaviour = function() {
  $('a.restore').unbind('click').on('click', function() {
    EOL.reveal_tab($(this).parent().attr('data-behaviour'), $(this).attr('href'));
    return(false);
  });
}

EOL.overview_thumbnails_behaviours = function() {
  (function($ss) {
    var placeholder = "<li class=\"placeholder\"></li>";

    $ss.each(function() {
      var $gallery = $(this),
          thumbs = [];
      if ($gallery.find('ul.thumbnails').length == 0) {
        // Insert ul.thumbnails, and for every large image use data-thumb to create thumbnail src.
        $("<ul />", { "class": "thumbnails" }).insertBefore($gallery.find("p.all"));
        $gallery.find(".image > a > img").each(function() {
          var $e = $(this),
              li;
          if ($e.is("[data-thumb]")) {
            li = "<li><a href=\"#\"><img src=\"" +
                      $e.attr("data-thumb") + "\" alt=\"" + $e.attr("alt") +
                      "\" /></a></li>";
          }
          else { li = placeholder; }
          thumbs.push(li);
        });
        // Insert placeholder list items up to max 4 items if < 4 large images.
        for (var i = 1, len = 4 - thumbs.length; i <= len; i++) {
          thumbs.push(placeholder);
        }
        $gallery.find(".thumbnails").html(thumbs.join(""));
        $gallery.find(".thumbnails li").not(".placeholder").eq(0).addClass("active");
      }
    });

    $ss.find(".image > a img").each(function() {
      this.onload = function() {
        $(this).data("height", this.height);
      };
    });

    $ss.find(".thumbnails").delegate("a", "click", function() {
      var $e = $(this).closest("li");
      $e.closest("ul").find(".active").removeClass("active");
      $e.addClass("active");
      return false;
    });

    if ("cycle" in $.fn) {
      $ss.find(".images").cycle({
        speed: 500,
        timeout: 0,
        pagerAnchorBuilder: function(idx) {
          return $ss.selector + " .thumbnails a:eq(" + idx + ")";
        }
      });

    }

  })($(".gallery"));
};

EOL.transitions = {duration: 150, easing: 'swing'};

EOL.back_button_behaviour = function() {
  $(window).unbind('popstate').bind('popstate', function(event) {
    if(history.state) {
      var hasSlash = /([^\/]+)\/([^\/]+)/;
      var match = hasSlash.exec(history.state)
      if (match === null) {
        EOL.reveal_tab(history.state, document.referrer, {skip_push: true});
      } else {
        EOL.reveal_tab(match[1], document.referrer, {skip_push: true});
        $('li[data-name='+match[2]+'] a').click();
      }
    }
  });
};

EOL.reveal_tab = function(name, href, options) {
  var $previous_tab = $('ul.nav .active');
  var previous_name = $previous_tab.attr('data-behaviour');
  var $contents = $('#content .site_column').children().not('.disclaimer');
  if (previous_name != name) {
    $previous_tab.removeClass('active').find('a').addClass('restore');
    $contents.hide(EOL.transitions);
  }
  $('ul.nav li[data-behaviour='+name+']').addClass('active').find('a').addClass('restore');
  $contents.not('.restored').addClass(previous_name+' restored');
  if (previous_name != name) {
    $('#content .site_column .'+name).show(EOL.transitions);
  }
  if ( ! options || ! options['skip_push']) {
    history.pushState(name, name, href);
  }
  if (name == 'details' || name == 'resources') {
    $('.page_actions .links').show(EOL.transitions);
  } else {
    $('.page_actions .links').hide(EOL.transitions);
  }
  console.log('restore tab');
  EOL.add_behaviours(name);
  EOL.back_button_behaviour();
  $('#page_heading .status, #flashes').fadeTo(2000, 0.1, function() { $(this).hide(400).remove(); });
};

EOL.add_behaviours = function(which) {
  console.log('add_behaviours');
  if (which == 'overview') {
    EOL.overview_thumbnails_behaviours();
    EOL.show_tree_behviour();
    EOL.feed_behaviour();
  } else if (which == 'media') { // These are all in the media_list file.
    EOL.init_image_collection_behaviors();
    EOL.media_list_open_images_behaviour();
    EOL.media_list_associations_behaviours();
    EOL.media_list_switch_entry_behaviours();
    EOL.media_list_filter_behaviours();
    EOL.media_video_behaviour();
    EOL.media_prefer_behaviour();
    EOL.media_exemplar_behaviour();
    EOL.enableRatings();
  } else if (which == 'names') {
    EOL.subtabby_behaviours('names');
  } else if (which == 'resources') {
    EOL.subtabby_behaviours('resources');
  } else if (which == 'communities') {
    EOL.subtabby_behaviours('communities');
  } else if (which == 'literature') {
    EOL.subtabby_behaviours('literature');
  } else if (which == 'resources') {
    EOL.subtabby_behaviours('resources');
  } else if (which == 'updates') {
    EOL.subtabby_behaviours('updates');
  }
  EOL.restorable_tabs_behaviour();
};

EOL.subtabby_behaviours = function(which) {
  $('#taxon_'+which+' ul.tabs a').on('click', function() {
    $('#taxon_'+which+' .main_container').fadeTo(225, 0.3);
    // Remembers the (main) tab we're on and the subtab that's open.
    var subtab_name = $(this).parent().attr('data-name');
    var state_name  = $('ul.nav .active').attr('data-behaviour')+"/"+subtab_name;
    if (history.state != state_name) { // Don't push it on if it's already there...
      history.pushState(state_name, subtab_name, $(this).attr('href'));
    }
    EOL.back_button_behaviour();
  })
};

EOL.fade_names_intro = function(new_text) {
  $('.article .copy p').fadeTo(125, 0).html(new_text).fadeTo(400, 1);
};

$(function() {

  // Use the 'select_submit' class to automatically submit forms that have a drop-down menu:
  $(".heading form.filter, form.select_submit").find(".actions").hide().find(":submit").end().end().find("select")
    .change(function() {
      $(this).closest("form").submit();
    });

  // TODO - we should probably just load the behaviors for the active tab (if any), yeah?
  EOL.add_behaviours('overview');
  console.log('common');
  EOL.add_behaviours('media');
  EOL.subtabby_behaviours('names');
  EOL.subtabby_behaviours('resources');
  EOL.subtabby_behaviours('communities');
  EOL.subtabby_behaviours('literature');
  EOL.subtabby_behaviours('updates');

  (function($language) {
    $language.find("p a").accessibleClick(function() {
      var $e = $(this),
          $ul = $e.closest($language.selector).find("ul");
      if ($ul.is(":visible")) {
        $ul.hide();
        return false;
      }
      $ul.show();
      $(document).click(function(e) {
        if (!$(e.target).closest($language.selector).length) {
          $language.find("ul").hide();
          $(this).unbind(e);
        }
      });
      return false;
    });
  })($(".language"));

  // Get the remote page title (given a URL by the user); used on the "add link" form
  (function($dato_source_url) {
    $dato_source_url.focusout(function() {
      if ($("#data_object_object_title").val() == "") {
        var data = "url=" + $dato_source_url.val() + "&lang=" + $('html').attr('lang');
        $.ajax({
          url: "/fetch_external_page_title",
          data: data,
          dataType: 'json',
          beforeSend: function(xhr) {
            $(".link_object span.errors").text($(".link_object span.errors").attr('data-pending_message'));
          },
          success: function(data) {
            if(data.exception == true) {
              $(".link_object span.errors").text(data.message);
            } else {
              $(".link_object span.errors").text("");
              if ($("#data_object_object_title").val() == "") {
                $("#data_object_object_title").val(data.message);
              }
            }
          }
        });
      }
    });
  })($(".link_object #data_object_source_url"));

  // Collecting happens through a modal dialog box (which is on many pages):
  $('a.collect').modal({
    beforeSend: function() { $('a.collect').fadeTo(225, 0.3); },
    beforeShow: function() {
      $('form#new_collection :submit').click(function() {
        if($('#collection_name').val() == ""){
          $('.collection_name_error').show();
          return(false);
        }
        if($('#flashes')[0] == undefined) {
          $('#page_heading div.page_actions').after('<div id="flashes" style="clear: both; width: 100%;"></div>');
        }
        EOL.ajax_submit($(this), { update: $('#flashes') });
        $('#choose_collections a.close').click();
        return(false);
      });
      $('form#new_collection_item :submit').click(function() {
        if($('#flashes')[0] == undefined) {
          $('#page_heading div.page_actions').after('<div id="flashes" style="clear: both; width: 100%;"></div>');
        }
        EOL.ajax_submit($(this), { update: $('#flashes') });
        $('#choose_collections a.close').click();
        return(false);
      });
      $('#choose_collections a.close_and_go').click(function() { $('#choose_collections a.close').click(); });
    },
    afterClose: function() {
      $('a.collect').delay(25).fadeTo(100, 1, function() {$('a.collect').css({filter:''}); });
    },
    duration: 200
  });

  // Allows placeholder text in form fields, which will disappear when the user enters the field and replace itself when the user leaves the
  // field:
  $("input[placeholder]").each(function() {
    var $e = $(this),
        placeholder = $e.attr("placeholder");
    $e.removeAttr("placeholder").val(placeholder);
    $e.bind("focus blur", function(e) {
      if (e.type === "focus" && $e.val() === placeholder) { $e.val(""); }
      else { if (!$e.val()) { $e.val(placeholder); } }
    });
  });

  // The reindex button on some pages doesn't actually submit, it's just a small Ajax call:
  $('a.reindex').click(function() {
    var $reindex = $('a.reindex')
    $reindex.fadeTo(225, 0.3);
    if($('#flashes')[0] == undefined) {
      $('#page_heading div.page_actions').after('<div id="flashes" style="clear: both; width: 100%;"></div>');
    }
    EOL.ajax_submit($(this), { url: $reindex.attr('href'), data: {}, update: $('#flashes') });
    return(false);
  });

  // Simple confirms (for I18n), currently only used for community-delete... TODO - why not just regular confirm?
  $('.button.confirm').click(function() {
    if(confirm($(this).attr('data_confirm'))) { return true; } else { return false; }
  });

  (function($content_partner_resources) {
    var $radios = $content_partner_resources.find("dl.resources :radio");
    $radios.change(function() {
      $radios.each(function() {
        var $radio = $(this);
        var $dd = $radio.closest("dt").next("dd");
        $radio.is(":checked") ? $dd.slideDown(200) : $dd.slideUp(200);
      });
    }).not(":checked").closest("dt").next("dd").hide();
  })($("#content_partner_resources"));

  $('ul.nav a[data-remote=true]').on('ajax:before', function(){
    $("#content .site_column > div:visible").fadeTo(150, 0.2);
  })

  $('ul.nav a[data-remote=true]').on('ajax:complete', function(){
    $("#content .site_column > div:visible").fadeTo(150, 1);
  })

});

(function($) {
  $.fn.accessibleClick = function(key_codes, cb) {
    if ("join" in key_codes) { key_codes.push(13); }
    else if (typeof key_codes === "function") { cb = key_codes; }
    else { return this; }
    return this.each(function() {
      $(this).click(function(e) {
        if ((!e.keyCode && e.layerY > 0) || e.layerY === undefined) { return cb.apply(this); }
        else { return false; }
      }).keyup(function(e) {
        if (e.keyCode === 13 || $.inArray(e.keyCode, key_codes) !== -1) {
          return cb.apply(this);
        }
      });
    });
  };

  $.fn.accessibleHover = function(over, out) {
    return this.bind('mouseenter mouseover focusin focus', over).bind('mouseleave mouseout focusout blur', out);
  };

  $.fn.hasAttr = function(attr) {
    return this.is("[" + attr + "]");
  };
})(jQuery);

// trying to generalize Ajax calls for EOL. Parameters:
//   el: The element firing the event.  It helps us find stuff, please pass it.
//   update: where you want the (html) response to go.  Defaults to the closest .editable item.
//   url: where you want the form to sumbit to.  Defaults to the data_url of the el you pass in, then to the nearest
//        form's action.
//   data: The data to send.  Defaults to the nearest form, serialized.
//   complete: Function to call when complete.  Optional.
//   type: method to use.  Defaults to POST.
EOL.ajax_submit = function(el, args) {
  args = typeof(args) != 'undefined' ? args : {};
  var form = (el == null) ? null : el.closest('form');
  var cell = '';
  if(typeof(args.update) != 'undefined') { cell = args.update; } else { cell = el.closest('.editable'); }
  var url  = '';
  if(typeof(args.url) != 'undefined') {
    url = args.url;
  } else if(typeof(el.attr('data_url')) != 'undefined') {
    url = el.attr('data_url');
  } else {
    url = form.attr('action');
  }
  var data = '';
  if(typeof(args.data) != 'undefined') { data = args.data; } else { data = form.serialize(); }
  complete = '';
  if(typeof(args.complete) != 'undefined') { complete = args.complete; }
  type = 'POST';
  if(typeof(args.type) != 'undefined') { type = args.type; }
  $.ajax({
    url: url,
    data: data,
    type: type,
    dataType: 'html',
    beforeSend: function(xhr) { cell.fadeTo(225, 0.3); },
    success: function(response) { cell.html(jQuery.trim(response)); },
    error: function(xhr, stat, err) { cell.html('<p>Sorry, there was an error: '+stat+'</p>'); },
    complete: function() {
      cell.delay(25).fadeTo(100, 1, function() {cell.css({filter:''});});
      if(complete != '') {
        complete();
      }
    }
  });
  return(false); // stop event... there's a better way to do this?
};

EOL.ajax_get = function(el, args) {
  var cell = '';
  if(typeof(args.update) != 'undefined') { cell = args.update; } else { cell = el.closest('.editable'); }
  complete = '';
  if(typeof(args.complete) != 'undefined') { complete = args.complete; }
  $.ajax({
    url: el.attr('href'),
    dataType: 'html',
    beforeSend: function(xhr) { cell.fadeTo(300, 0.3); },
    success: function(response) { cell.html(response); },
    error: function(xhr, stat, err) { cell.html('<p>Sorry, there was an error: '+stat+'</p>'); },
    complete: function() {
      cell.delay(25).fadeTo(100, 1, function() {cell.css({filter:''});});
      if(complete != '') {
        complete();
      }
    }
  });
  return(false); // stop event... there's a better way to do this?
};

// Third party scripts for social plugins
EOL.loadTwitter = function() {
  if($(".twitter-share-button").length > 0){
    if (typeof (twttr) !== 'undefined') {
      twttr.widgets.load();
      EOL.initTwitter();
    } else {
      $.getScript("http://platform.twitter.com/widgets.js", function() { EOL.initTwitter(); });
    }
  }
};
EOL.initTwitter = function() {
  if (typeof(_ga) !== 'undefined') {
    _ga.trackTwitter();
  }
};
EOL.loadFacebook = function(app_id, channel_url) {
  if ($("#fb-root").length > 0) {
    if (typeof (FB) !== 'undefined') {
      EOL.initFacebook();
    } else {
      $.getScript("http://connect.facebook.net/en_US/all.js", function() { EOL.initFacebook(app_id, channel_url); });
    }
  }
};
EOL.initFacebook = function(app_id, channel_url) {
  FB.init({
    appId      : app_id,
    channelUrl : channel_url,
    logging    : true,
    status     : true,
    cookie     : true,
    xfbml      : true
  });
  if (typeof(_ga) !== 'undefined') {
    _ga.trackFacebook();
  }
};

// Use this function to load the javascript after the page is rendered.
EOL.after_onload_JS = function(jsFile) {
  (function(w, d, s) {
    function go(){
      head.js(jsFile);
    }
    if (w.addEventListener) { w.addEventListener("load", go, false); }
    else if (w.attachEvent) { w.attachEvent("onload",go); }
  }(window, document, 'script'));
};
