if(!EOL) { var EOL = {}; }

// TODO - not all of these are required, if we know we won't use them:
$.ajaxSetup({accepts: {
  '*': "text/javascript, */*",
  html: "text/javascript",
  json: "application/json, text/javascript",
  script: "text/javascript",
  text: "text/plain",
  xml: "application/xml, text/xml"
}});

// Globally change cursor to busy when we're waiting on AJAX event to finish.
$("html").bind("ajaxStart", function(){
  $(this).addClass('busy');
}).bind("ajaxStop", function(){
  $(this).removeClass('busy');
});

$(function() {

  $(".heading form.filter, form.select_submit").find(".actions").hide().find(":submit").end().end().find("select")
    .change(function() {
      $(this).closest("form").submit();
    });

  (function($ss) {
    var placeholder = "<li class=\"placeholder\"></li>";

    $ss.each(function() {
      var $gallery = $(this),
          thumbs = [];
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
      for (var i = 1, len = 4 - thumbs.length; i <= len; i++) {
        thumbs.push(placeholder);
      }
      $gallery.find(".thumbnails").html(thumbs.join(""));
      $gallery.find(".thumbnails li").not(".placeholder").eq(0).addClass("active");
    });

    $ss.find(".image img").each(function() {
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

    function toggleImg(idx) {
      var $image = $ss.find(".image:eq(" + idx + ")");
      var $a = $image.find("> a").first();
      var $img = $a.find("img");
      $img.css("paddingTop", ($a.height() / 2 - $img.data("height") / 2) + "px");
      $ss.find(".images").css("height", $image.height());
    }

    if ("cycle" in $.fn) {
      $ss.find(".images").cycle({
        speed: 500,
        timeout: 0,
        onPagerEvent: toggleImg,
        pagerAnchorBuilder: function(idx) {
          return $ss.selector + " .thumbnails a:eq(" + idx + ")";
        }
      });

      if ($ss.find(".image").length > 1) {
        toggleImg(0);
      }

    }

  })($(".gallery"));

  (function($media_list) {
    $media_list.find("li .overlay").click(function() {
      window.location = $(this).parent().find("a").attr("href");
      return false;
    });
  })($("#media_list"));

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

  (function($collection) {
    var zi = 1000;
    $collection.find("ul.collection_gallery").children().each(function() {
      var $li = $(this);
      if ($.browser.msie) {
        $li.css('z-index', zi);
        zi -= 1;
      }
      if (!$li.find(".checkbox input[type=checkbox]").is(':checked')) {
        $li.find(".checkbox").hide();
      }
      $li.find("h4").hide();
      $li.accessibleHover(
        function() {
          $(this).find(".checkbox").show();
          $(this).find("h4").addClass('balloon').show();
        },
        function() {
          if (!$(this).find(".checkbox input[type=checkbox]").is(':checked')) {
            $(this).find(".checkbox").hide();
          }
          $(this).find("h4").hide().removeClass('balloon');
      });
    });

    $collection.find("ul.object_list").children().each(function() {
      var $li = $(this);
      $li.delegate("p.edit a", "click", function( event ) {
        event.preventDefault();
        $(this).parent().parent().hide().after('<div class="collection_item_form"></div>');
        var $update = $(this).parent().parent().next('.collection_item_form');
        EOL.ajax_get($(this), {update: $update, type: 'GET'});
      });
      $li.delegate(".collection_item_form a", "click", function( event ) {
        event.preventDefault();
        $(this).closest(".collection_item_form").hide().prev().show().end().html('');
      });
      $li.delegate(".collection_item_form input[type='submit']", "click", function( event ) {
        event.preventDefault();
        var $ci_form = $(this).closest(".collection_item_form")
        EOL.ajax_submit($(this), {
          data: "_method=put&commit_annotation=true&" +
            $ci_form.find("input, textarea").serialize(),
            update: $ci_form.prev(),
            complete: function() { $ci_form.hide().remove(); }
        });
      });
    });
    $collection.find('#sort_by').change(function() {
      $(this).closest('form').find('input[name="commit_sort"]').click();
    });
    $collection.find('input[name="commit_sort"]').hide();
    $collection.find('#view_as').change(function() {
      $(this).closest('form').find('input[name="commit_view_as"]').click();
    });
    $collection.find('input[name="commit_view_as"]').hide();
  })($("#collections"));

  $("input[placeholder]").each(function() {
    var $e = $(this),
        placeholder = $e.attr("placeholder");
    $e.removeAttr("placeholder").val(placeholder);
    $e.bind("focus blur", function(e) {
      if (e.type === "focus" && $e.val() === placeholder) { $e.val(""); }
      else { if (!$e.val()) { $e.val(placeholder); } }
    });
  });

  // Collecting happens through a modal dialog box:
  $('a.collect').modal({
    beforeSend: function() { $('a.collect').fadeTo(225, 0.3); },
    beforeShow: function() {
      $('#choose_collections form :submit').click(function() {
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

  // Wouldn't it be nice if ratings were Ajaxified?
  $('.media .ratings .rating ul > li > a').click(function() {
    var $update = $(this).closest('div.ratings');
    EOL.ajax_submit($(this), {url: $(this).attr('href'), update: $update, type: 'GET'});
    return(false);
  });

  // initiates march of life on homepage
  $('.thumbnails ul li').each(function() {
    var number_of_slides = $('.thumbnails ul li').length;
    var index = $(this).index();
    var random = new Array(-3, 1, 0, -2, -4, -1);
    var display_time = 5000;
    var transition_time = 1800;
    $(this).cycle({
      fx: 'fade',
      timeout: number_of_slides * display_time,
      delay: random[index] * display_time,
      speed: transition_time
    });
  });

  // properly shows the march of life name on mouseover
  $(".thumbnails li img").unbind().mouseover(function() {
    var $e = $(this).parent().parent();
    $thumbs = $e.closest(".thumbnails");
    // margin = $thumbs.find("li").eq(0).outerWidth(true) - $e.outerWidth();
    var term_p = $thumbs.find(".term p");
    var left_pos = $e.position().left - 100 + 5;
    var right_pos = term_p.outerWidth(true) - $e.position().left - $e.outerWidth(true) - 100;
    if($e.is($(".thumbnails li:last"))) {
      right_pos = right_pos - 15;
    }
    term_p.css({
      textAlign: 'center'
    }).css("margin-left", left_pos+"px").css("margin-right", right_pos+"px").text($(this).attr("alt"));
  }).eq(0).mouseover();

  // removes the homepage march of life name on mouseout
  $(".thumbnails li").mouseout(function() {
    $(".thumbnails .term p").html("&nbsp;");
  });

  // uncheck search filter All when other options are selected
  $("#main_search_type_filter input[type=checkbox][value!='all']").click(function() {
    $("#main_search_type_filter input[type=checkbox][value='all']").removeAttr("checked");
  });
  // uncheck all other search filter options when All is selected
  $("#main_search_type_filter input[type=checkbox][value='all']").click(function() {
    $("#main_search_type_filter input[type=checkbox][value!='all']").removeAttr("checked");
  });
  // disable the checkboxes for filter categories with no results
  $("#main_search_type_filter li.no_results input[type=checkbox]").attr("disabled", true);

  // Search should not allow you to search without a term:
  $("#simple_search :submit").click(function() {
    var $q = $("#simple_search :submit").closest('form').find('#q');
    if ($q.val() == $(this).attr('data_unchanged')) {
      $q.css('color', '#aa0000').val($(this).attr('data_error')).click(function() { $(this).val('').css('color', 'black').unbind('click') });
      return(false);
    } else if ($q.val() == $(this).attr('data_error')) {
      var blinkspeed = 160;
      $q.css('color', '#aa0000').fadeOut(blinkspeed).fadeIn(blinkspeed).fadeOut(blinkspeed).fadeIn(blinkspeed).fadeOut(blinkspeed).fadeIn(blinkspeed);
      return(false);
    }
  });

  // uncheck media list filter All when other options are selected
  $("#media_list #sidebar input[type=checkbox][value!='all']").click(function() {
    $("#media_list #sidebar input[type=checkbox][value='all'][name='"+ $(this).attr('name') +"']").removeAttr("checked");
  });
  // uncheck all other media list filter options when All is selected
  $("#media_list #sidebar input[type=checkbox][value='all']").click(function() {
    $("#media_list #sidebar input[type=checkbox][value!='all'][name='"+ $(this).attr('name') +"']").removeAttr("checked");
  });
  // disable the checkboxes for filter categories with no results
  $("#media_list #sidebar li.no_results input[type=checkbox]").attr("disabled", true);

  $('.button.confirm').click(function() {
    if(confirm($(this).attr('data_confirm'))) { return true; } else { return false; }
  });

  // When you select all items, hide the checkboxes (and vice-versa) on collection items:
  $('form.edit_collection #scope').change(function() {
    if ($('form.edit_collection #scope').val() == 'all_items') {
      $('#collection_items :checkbox').parent().hide();
    } else {
      $('#collection_items :checkbox').parent().show();
    }
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

  EOL.get_notifications_counts();

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
  var form = el.closest('form');
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

EOL.get_notifications_counts = function() {
  $('#header .session > ul li').each(function() {
    var $a = $(this).find('a');
    if ($a != undefined) {
      console.log($a);
      $.ajax({
        url: $a.attr('href'),
        dataType: 'html',
        success: function(response) { $a.html(response); }
      });
    }
  });
}
