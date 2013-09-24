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

$(function() {

  $(".heading form.filter, form.select_submit").find(".actions").hide().find(":submit").end().end().find("select")
    .change(function() {
      $(this).closest("form").submit();
    });

  // Taxon overview media summary behaviours.
  (function($ss) {
    var placeholder = "<li class=\"placeholder\"></li>";

    $ss.each(function() {
      var $gallery = $(this),
          thumbs = [];
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

    $collection.find('#sort_by').change(function() {
      $(this).closest('form').find('input[name="commit_sort"]').click();
    });
    $collection.find('input[name="commit_sort"]').hide();
    $collection.find('#view_as').change(function() {
      $(this).closest('form').find('input[name="commit_view_as"]').click();
    });
    $collection.find('input[name="commit_view_as"]').hide();
    $collection.find('input[name="commit_filter"]').hide();
  })($("#collection"));

  $("input[placeholder]").each(function() {
    var $e = $(this),
        placeholder = $e.attr("placeholder");
    $e.removeAttr("placeholder").val(placeholder);
    $e.bind("focus blur", function(e) {
      if (e.type === "focus" && $e.val() === placeholder) { $e.val(""); }
      else { if (!$e.val()) { $e.val(placeholder); } }
    });
  });

  // TODO - generalize this with the other modals...
  $('#collection_items .editable .edit a').modal({
    beforeSend: function() { $('#collection_items .editable a').fadeTo(225, 0.3); },
    beforeShow: function() {
      $('form.edit_collection_item :submit').click(function() {
        EOL.ajax_submit($(this), { update: $('li#collection_item_'+$(this).attr('data-id')+' div.editable') });
        $('#collection_items_edit a.close').click();
        return(false);
      });
    },
    afterClose: function() {
      $('#collection_items .editable a').delay(25).fadeTo(100, 1, function() {$('#collection_items .editable a').css({filter:''}); });
    },
    duration: 200
  });

  // Collecting happens through a modal dialog box:
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

  $('a.reindex').click(function() {
    var $reindex = $('a.reindex')
    $reindex.fadeTo(225, 0.3);
    if($('#flashes')[0] == undefined) {
      $('#page_heading div.page_actions').after('<div id="flashes" style="clear: both; width: 100%;"></div>');
    }
    EOL.ajax_submit($(this), { url: $reindex.attr('href'), data: {}, update: $('#flashes') });
    return(false);
  });

  EOL.enableRatings();

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
      speed: transition_time,
      before: loadMoreMarchOfLife
    });
    var random_index = Math.floor(Math.random() * 6) + 1;
    initiate_alt_text_for_march_of_life($(".thumbnails li:nth-child(" + random_index + ") img:first"));
  });

  // this method is used to grab more images for the march of life before callback
  function loadMoreMarchOfLife(curr, next, opts) {
    // on the first pass, addSlide is undefined (plugin hasn't yet created the fn); 
    // when we're finshed adding slides we'll null it out again 
    if (!opts.addSlide) return;

    cycle_list_item = $(this).closest('li');
    number_of_images_in_li = cycle_list_item.find('img').size();
    if(number_of_images_in_li < 10) {
      // call to get more images
      $.getJSON('content/random_homepage_images?count=5', function(data) {
        // make sure there were no errors, 
        if(!data['error']) {
          for(i = 0 ; i < data.length ; i++) {
            image_data = data[i];
            // make sure this image isn't already featured on this page
            if($("img[src='" + image_data['image_url'] + "']").size() == 0) {
              // add the HTML for the new image
              scientific_name = image_data['taxon_scientific_name'];
              common_name = image_data['taxon_common_name'];
              if(common_name == null) {
                common_name = '';
              }
              alt_text = scientific_name;
              opts.addSlide('<a href="'+ image_data['taxon_page_path'] + '"><img src="' +
                image_data['image_url'] +
                '" alt="' + alt_text + 
                '" data-scientific_name="' + scientific_name + 
                '" data-common_name="' + common_name + 
                '" width="130" height="130"/></a>');
              // since we had to add a slide we need to change the index of the next slide
              opts.nextSlide = opts.currSlide + 1;
              enable_mouseover_alt_text_for_march_of_life();
            }
          }
        }
      });
      if(cycle_list_item.hasClass("hover")) {
        initiate_alt_text_for_march_of_life($(next).find("img"));
      }
    }
  };

  function enable_mouseover_alt_text_for_march_of_life() {
    // properly shows the march of life name on mouseover
    $(".thumbnails li img").unbind().mouseover(function() { 
      initiate_alt_text_for_march_of_life($(this));
    });
  }
  
  function initiate_alt_text_for_march_of_life(img) {
    var $e = img.parent().parent();
    if ($e.length > 0) {
      $thumbs = $e.closest(".thumbnails");
      var term_p = $thumbs.find(".term p");
      var left_pos = $e.position().left - 100 + 5;
      var right_pos = term_p.outerWidth(true) - $e.position().left - $e.outerWidth(true) - 100;
      if($e.is($(".thumbnails li:last"))) {
        right_pos = right_pos - 15;
      }
      var line_height = 'inherit';
      if(img.attr("data-common_name") == null || img.attr("data-common_name") == '') {
        line_height = $thumbs.find(".term .site_column").css("height");
      }
      var name_html = '<span class="scientific">' + img.attr("data-scientific_name") + '</span>';
      if(img.attr("data-common_name") != null && img.attr("data-common_name") != '') {
        name_html += '<span class="common">' + img.attr("data-common_name") + '</span>';
      }
      term_p.css({
        textAlign: 'center'
      }).css("margin-left", left_pos+"px").css("margin-right", right_pos+"px").css("line-height", line_height).html(name_html);
      $(".thumbnails li").removeClass("hover");
      $e.addClass("hover");
    }
  }
  enable_mouseover_alt_text_for_march_of_life();

  // uncheck search filter All when other options are selected
  $("#main_search_type_filter input[type=checkbox][value!='all']").click(function() {
    $("#main_search_type_filter input[type=checkbox][value='all']").prop("checked", false);
  });
  // uncheck all other search filter options when All is selected
  $("#main_search_type_filter input[type=checkbox][value='all']").click(function() {
    $("#main_search_type_filter input[type=checkbox][value!='all']").prop("checked", false);
  });
  // disable the checkboxes for filter categories with no results
  $("#main_search_type_filter li.no_results input[type=checkbox]").attr("disabled", true);

  // Search should not allow you to search without a term:
  $("#simple_search :submit").click(function() {
    var $q = $("#simple_search :submit").closest('form').find('#q');
    if ($q.val() == $(this).attr('data_unchanged')) {
      $q.css('color', '#aa0000').val($(this).attr('data_error')).click(function() { $(this).val('').css('color', 'black').unbind('click'); });
      return(false);
    } else if ($q.val() == $(this).attr('data_error')) {
      var blinkIn = 20;
      var blinkOut = 240;
      $q.css('color', '#aa0000').fadeOut(blinkOut).fadeIn(blinkIn).fadeOut(blinkOut).fadeIn(blinkIn).fadeOut(blinkOut).fadeIn(blinkIn);
      return(false);
    }
  });

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

  $('.button.confirm').click(function() {
    if(confirm($(this).attr('data_confirm'))) { return true; } else { return false; }
  });

  // When you select all items, hide the checkboxes (and vice-versa) on collection items:
  $('form.new_collection_job #scope').change(function() {
    if ($('form.new_collection_job #scope').val() == 'all_items') {
      $('#collection_items :checkbox').parent().hide();
    } else {
      $('#collection_items :checkbox').parent().show();
    }
  });
  
  
  $('#main .media video embed').each(function() {
    var test_video = document.createElement('video');
    cant_play_video = (!test_video.canPlayType || !test_video.canPlayType('video/mp4'));
    if (cant_play_video) {
      var video = $(this).parent();
      video.parent().html(video.html());
    }
  });
  
  
  (function($inat_link) {
    $inat_link.attr('href', function() { 
      auth_provider = $('.inat_observations_header a.button').attr('href').split("&")[1];
      if (typeof auth_provider != "undefined") {
        return this.href + '?' + auth_provider;
      }
    });
  })($(".inat_top_contributors a"));

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

  // This may warrant its own JS, but it's tiny, so it was easy enough to stick here:
  $('td.preferred_entry_selector input[type="radio"]:not(:checked)').click(function() {
    var form = $(this).closest('form');
    form.submit();
  });

  // EOL Statistics initialise date picker
  (function($statistics) {
    var $date_form = $statistics.find('form');

    var $datepicker_opts = $.extend(
      $date_form.data('datepicker_opts'),
      { isRTL: ($('body').css('direction') == 'rtl') ? true : false,
        showOn: "button",
        buttonImage: "/assets/v2/icon_calendar.png",
        buttonImageOnly: true,
        minDate: new Date(2012, 2 - 1, 17),
        maxDate: new Date() }
    );

    $date_form.addClass('with_picker');
    $date_form.find('label').each(function() {
      var $label = $(this);
      $label.append('<input type="hidden"/>');
      $label.find('input[type="hidden"]').datepicker($.extend($datepicker_opts, {
        defaultDate: new Date($label.find('select:eq(2)').val(),
                              $label.find('select:eq(1)').val() - 1,
                              $label.find('select:eq(0)').val()),
        onSelect: function(dateText, inst) {
          $label.find('option:selected').removeAttr('selected');
          $label.find('select:eq(0) option[value="' + inst.selectedDay + '"]').attr('selected', 'selected');
          $label.find('select:eq(1) option[value="' + (inst.selectedMonth + 1) + '"]').attr('selected', 'selected');
          $label.find('select:eq(2) option[value="' + inst.selectedYear + '"]').attr('selected', 'selected');
          $label.closest('form').submit();
        }
      }));
    });
  })($("#statistics"));
  
  (function($flash_div) {
    $flash_div.delay('5000').fadeOut('slow');
  })($("#flash-bad, #flash-good"));

  $('input.clear_on_focus').each(function() { $(this).val($(this).attr('data-default')); });
  $('input.clear_on_focus').siblings().each(function() { $(this).on('click', function() {
    if ($(this).prop('checked')) {
      $(this).siblings().focus()
    }
  })});
  $('input.clear_on_focus').on('focus', function() {
    if ($(this).val() == $(this).attr('data-default')) {
      $(this).val('');
      EOL.check_siblings(this, true);
    }
  });
  $('input.clear_on_focus').on('blur', function() {
    if ($(this).val() == '' || $(this).val() == $(this).attr('data-default')) {
      $(this).val($(this).attr('data-default'));
      EOL.check_siblings(this, false);
    }
  });

  $('input#collection_job_overwrite').on('click', function() {
    if ($(this).prop('checked')) {
      $('form#new_collection_job li.collected input').prop('checked', false).attr("disabled", false);
    } else {
      $('form#new_collection_job li.collected input').prop('checked', true).attr("disabled", true);
    }
  });

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

EOL.enableRatings = function() {
  // Wouldn't it be nice if ratings were Ajaxified?
  $('.media .ratings .rating ul > li > a').unbind('click').click(function() {
    var $update = $(this).closest('div.ratings');
    EOL.ajax_submit($(this), {url: $(this).attr('href'), update: $update, type: 'GET'});
    return(false);
  });
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
