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
      $gallery.find(".image > img").each(function() {
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
      for (var i = 1, len = 4 - thumbs.length; i < len; i++) {
        thumbs.push(placeholder);
      }
      $gallery.find(".thumbnails").html(thumbs.join(""));
      $gallery.find(".thumbnails li").not(".placeholder").eq(0).addClass("active");
    });

    var loading_complete = $ss.find(".image").length;
    $ss.find(".image > img").each(function() {
      this.onload = function() {
        if (!--loading_complete) {
          var h = $ss.find(".images").height();
          h -= parseInt($ss.find(".image").css("padding-bottom"), 10);
          $ss.find(".image > img").each(function() {
            var top = (h / 2 - this.height / 2);
            top = top < 0 ? 0 : top;
            $(this).css("top", top + "px");
          });
        };
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

  (function($collection) {
    $collection.find("ul.object_list li").each(function() {
      var $li = $(this);
      $li.find("p.edit").show().next().hide().end().find("a").click(function() {
        $(this).parent().hide().next().show();
      });
      $li.find("form a").click(function() {
        $(this).closest("form").hide().prev().show();
      });
    });
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

  // Add to collection buttons should be Ajaxy:
  $('form#new_collection_item').find('input.button').click(function() {
    var $f = $(this).closest('form');
    EOL.ajax_submit($(this), {update: $f})
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
    var $e = $(this).parent().parent(),
        $thumbs = $e.closest(".thumbnails"),
        margin = $thumbs.find("li").eq(0).outerWidth(true) - $e.outerWidth();
        direction = ($e.index() > $thumbs.find("li").length / 2 - 1) ? "right" : "left";
        pos = $e.position();
    pos.right = $thumbs.find("ul").width() - $e.outerWidth() - pos.left + margin;
    $thumbs.find(".term p").css({
      margin: 0,
      textAlign: direction
    }).css("margin-" + direction, pos[direction]).text($(this).attr("alt"));
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


  // uncheck media list filter All when other options are selected
  $("#media_list #sidebar input[type=checkbox][value!='all']").click(function() {
    $("#media_list #sidebar input[type=checkbox][value='all'][name='"+ $(this).attr('name') +"']").removeAttr("checked");
  });
  // uncheck all other media list filter options when All is selected
  $("#media_list #sidebar input[type=checkbox][value='all']").click(function() {
    $("#media_list #sidebar input[type=checkbox][value!='all'][name='"+ $(this).attr('name') +"']").removeAttr("checked");
  });
  $('#classifications_summary a.show_tree').click(function() {
    var $update = $(this).closest('#classifications_summary > ul > li').find('.classification.summary');
    EOL.ajax_submit($(this), {update: $update, type: 'GET'})
    return(false);
  });
  $('.button.confirm').click(function() {
    if(confirm($(this).attr('data_confirm'))) {
      return true;
    } else {
      return false;
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

  $.fn.hasAttr = function(attr) {
    return this.is("[" + attr + "]");
  };
})(jQuery);

// trying to generalize Ajax calls for EOL. Parameters:
//   el: The element firing the event.  It helps us find stuff, please pass it.
//   update: where you want the (html) response to go.  Defaults to the closest .editable item.
//   url: where you want the form to subit to.  Defaults to the data_url of the el you pass in, then to the nearest
//        form's action.
//   data: The data to send.  Defaults to the nearest form, serialized.
//   complete: Function to call when complete.  Optional.
//   type: method to use.  Defaults to POST.
EOL.ajax_submit = function(el, args) {
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
  $.ajax({
    url: el.attr('href'),
    dataType: 'html',
    beforeSend: function(xhr) { cell.fadeTo(300, 0.3); },
    success: function(response) { cell.html(response); },
    error: function(xhr, stat, err) { cell.html('<p>Sorry, there was an error: '+stat+'</p>'); },
    complete: function() {
      cell.delay(25).fadeTo(100, 1, function() {cell.css({filter:''});});
    }
  });
  return(false); // stop event... there's a better way to do this?
};

