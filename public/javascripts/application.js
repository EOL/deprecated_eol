$(document).ready(function() {
  $('.thumbnails ul li').each(function() {
    var number_of_slides = $('.thumbnails ul li').length;
    var index = $(this).index();
    var random = new Array(-4, 0, -1, -3, -5, -2);
    var display_time = 4000;
    var transition_time = 1500;
    $(this).cycle({
      fx: 'fade',
      timeout: number_of_slides * display_time,
      delay: random[index] * display_time,
      speed: transition_time
    });
  });
});

// function stepMarchOfLife() {
//   $('.thumbnails ul li:first a:first').appendTo('.thumbnails ul li:first')
//   if($('.thumbnails ul li:first img').length > 1) {
//     $('.thumbnails ul li:first img:last').css({
//       opacity:0
//     });
//   }
//   $('.thumbnails ul li:first img:first').css({
//     opacity:1
//   });
//   $('.thumbnails ul li:first').appendTo('.thumbnails ul');
//   $('.thumbnails ul li').removeClass('last');
//   $('.thumbnails ul li:last').addClass('last');
// }

$(function() {
  $(".thumbnails li img").mouseover(function() {
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
  
  // setInterval(function() {
  //   stepMarchOfLife();
  // }, 3000);
  
  $(".thumbnails li").mouseout(function() {
    $(".thumbnails .term p").html("&nbsp;");
  });

  $(".heading form.filter, form.select_submit").find(":submit").hide().end().find("select")
    .change(function() {
      $(this).closest("form").submit();
    });

  (function($filters) {
    $filters.find("button.select_all").show().click(function() {
      $(".main_container").find(":checkbox").prop("checked", true);
      return false;
    });
  })($(".filters"));

  (function($ss) {
    $ss.each(function() {
      var $gallery = $(this),
          thumbs = [];
      $("<ul />", { "class": "thumbnails" }).insertBefore($gallery.find("p.all"));
      $gallery.find(".image > img").each(function() {
        var $e = $(this);
        thumbs.push("<li><a href=\"#\"><img src=\"" +
                    $e.attr("data-thumb") + "\" alt=\"" + $e.attr("alt") +
                    "\" /></a></li>");
      });
      $gallery.find(".thumbnails").html(thumbs.join(""));
      $gallery.find(".thumbnails li").eq(0).addClass("active");
    });

    var loading_complete = $ss.find(".image").length;
    $ss.find(".image > img").each(function() {
      this.onload = function() {
        if (!--loading_complete) {
          var h = $ss.find(".images").height();
          h -= parseInt($ss.find(".image").css("padding-bottom"), 10);
          $ss.find(".image > img").each(function() {
            $(this).css("top", (h / 2 - this.height / 2) + "px");
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

  $("input[placeholder]").each(function() {
    var $e = $(this),
        placeholder = $e.attr("placeholder");
    $e.removeAttr("placeholder").val(placeholder);
    $e.bind("focus blur", function(e) {
      if (e.type === "focus" && $e.val() === placeholder) { $e.val(""); }
      else { if (!$e.val()) { $e.val(placeholder); } }
    });
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
})(jQuery);
